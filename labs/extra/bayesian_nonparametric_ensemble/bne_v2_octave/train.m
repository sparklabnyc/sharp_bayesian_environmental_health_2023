function [W,RP,wvar,sigW,Zs,Zt,piZ,mse] = train(y, space, time, models, ...
    scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, ... % todo: adapt other scripts
    lambda_w, lambda_rp, time_metric, opt_stage, seed, bne_mode, sample_n)
% % Implements a stochastic optimization (MAP inference) version of BNE.
% %
% % === Inputs ===
% %
% %     y : vector or measurements, N space 1
% %     space : geographic locations for measurements in y, N space 2 (we use lat-long)
% %     time : time stamp for measurements in y, N space 1 ( we use 1 unit = 1 day)
% %     models : model predictions for each measurement, N space (number of models)
% %     num_rand_feat : dimensionality of random features (we've found 500 to be plenty)
% %     scale_space_w : RBF spatial kernel parameter (we've been using 6.5, but not optimized)
% %     scale_time_w : RBF temporal kernel parameter (we've been using 17.5, but not optimized)
% %     scale_space_rp : RBF spatial kernel parameter (we've been using 6.5, but not optimized)
% %     scale_time_rp : RBF temporal kernel parameter (we've been using 17.5, but not optimized)
% %     bool_periodic : indicates that the time-varying portion of the kernel should repeat each year
% %
% %  === Outputs ===
% %
% %     W : num_rand_feat space num_models parameters for each model
% %     rp : num_rand_feat space 1 parameters for bias term
% %     sigW : Covariance of W and rp for Gaussian approximation.
% %             Comment: This is for all parameters in W and rp combined by vectorizing
% %             the columns of W first and then appending rp to the end, so it is large.
% %             I check to see if it is positive semidefinite as required. I've noticed sometimes
% %             it isn't, which is strange and I need to look more into it. If not, I
% %             currently set any negative eigenvalues to zero and recalculate.
% %     Z & piZ : The random variables used to calculate the random
% %                features (Phi in code). Need to use the same ones for prediction.

%%%% ------------------------------ %%%%
%%%% 0: Set Up Objects for Test Run %%%%
%%%% ------------------------------ %%%%

% models = trainPreds; y = trainAqs; space = trainSpace; time = trainTime;


%%%% ---------------------------------- %%%%
%%%% 1: Set Up Objects for Optimization %%%%
%%%% ---------------------------------- %%%%

% 1.a. set the number of random features
% 500 is generally sufficient
num_rand_feat = sample_n;

% 1.b. determine the dimensions we are working with
[num_obs,num_models] = size(models);
dimspace = size(space,2);

% 1.c. intitialize the parameter values at zero
W = zeros(num_rand_feat,num_models);
RP = zeros(num_rand_feat,1);
wvar = zeros(num_rand_feat,1);

% 1.d. create mapping for RFF random features
% 1.d.i. spatial dimensions
Zs = randn(num_rand_feat,dimspace);
% 1.d.ii temporal dimenion
if strcmp(time_metric, 'percentOfYear')
    % 2D time for year invariance, but seasonal variation
    Zt = randn(num_rand_feat,2);
else
    % One dimensional time - julian date since start of study period
    Zt = randn(num_rand_feat,1);
end
% 1.d.iii. another component
piZ = 2*pi*rand(num_rand_feat,1);

% 1.e. Set SNR to 8. This can be changed.
% we can just keep at 8 because we choose the penalties, which impacts
% optimization in the same way as the signal:noise aka noise: true variance
%noise = var(y)/8;

% 1.f. determin the number of data points to randomly sample per model parameter update
if num_obs < 10000
    batch_size = 500;
    if batch_size > num_obs % added for reduced number of observations
        batch_size = num_obs;
    end
else
    batch_size = 2000;
end

% 1.g. initialize the error
err = 100;
mse = 0;

% 1.h. set the seed
rand('state',seed);

%%%% ---------------------- %%%%
%%%% 2: Optimize Parameters %%%%
%%%% ---------------------- %%%%

% 2.0. begin loop

if strcmp(bne_mode, 'testBNE')
    max_iter = 200;
else
    max_iter = 50; % testing with 50 for fast computation purposes; recommended value is 2000
end

for iter = 1:max_iter
    rho = .1;

    % 2.a. Subsample batch_size number of points
    [~,idx] = sort(rand(1,num_obs));
    idx = idx(1:batch_size);

    % 2.b. Construct "random" features for those points.
    % (The randomness happens once at the beginning of loop)
    if strcmp(time_metric, 'percentOfYear')
        phi_w = sqrt(2/num_rand_feat)*cos(Zs*space(idx,:)'/scale_space_w + ...
            Zt*58.0916*[cos(2*pi*time(idx))' ; sin(2*pi*time(idx))']/scale_time_w + piZ*ones(1,batch_size));
        phi_rp = sqrt(2/num_rand_feat)*cos(Zs*space(idx,:)'/scale_space_rp + ...
             Zt*58.0916*[cos(2*pi*time(idx))' ; sin(2*pi*time(idx))']/scale_time_rp + piZ*ones(1,batch_size));
        phi_wvar = sqrt(2/num_rand_feat)*cos(Zs*space(idx,:)'/scale_space_wvar + ...
             Zt*58.0916*[cos(2*pi*time(idx))' ; sin(2*pi*time(idx))']/scale_time_rp + piZ*ones(1,batch_size)); % todo: play with time evolution
    else
        phi_w = sqrt(2/num_rand_feat)*cos(Zs*space(idx,:)'/scale_space_w + ...
            Zt*time(idx)'/scale_time_w + piZ*ones(1,batch_size));
        phi_rp = sqrt(2/num_rand_feat)*cos(Zs*space(idx,:)'/scale_space_rp + ...
                Zt*time(idx)'/scale_time_rp + piZ*ones(1,batch_size));
        phi_wvar = sqrt(2/num_rand_feat)*cos(Zs*space(idx,:)'/scale_space_wvar + ...
                Zt*time(idx)'/scale_time_rp + piZ*ones(1,batch_size));
    end

    % 2.c Calculate stochastic gradient and update model GP vectors
    dotWPhi = W'*phi_w;
    softmax = exp(dotWPhi);
    softmax = softmax./repmat(sum(softmax,1),num_models,1);
    model_avg = sum(softmax.*models(idx,:)',1);
    dotRPPhi = RP'*phi_rp;
    prec = exp(-phi_w'*wvar);
    error = y(idx)' - model_avg - dotRPPhi;
    grad = phi_w*((repmat(error,num_models,1).*(models(idx,:)' -  ...
        repmat(model_avg,num_models,1)).*softmax)'.*repmat(prec,1,num_models)) - lambda_w*W;
    W = W + rho*grad/sqrt(iter);
    ... % jb: not used(1/noise)*
    % 2.d Update the residual process vector, if we are doing the one-stage
    % optimization
    %if opt_stage == 1
    dotWPhi = W'*phi_w;
    softmax = exp(dotWPhi);
    softmax = softmax./repmat(sum(softmax,1),num_models,1);
    model_avg = sum(softmax.*models(idx,:)',1);
        %dotRPPhi = RP'*phi_rp; jb = not used
    residual = y(idx) - model_avg'; %- dotRPPhi;
        %RPtmp = inv(lambda_rp*noise*eye(num_rand_feat) + phi_rp*phi_rp')*(phi_rp*residual);
        %RP = rptmp/sqrt(iter) + (1-1/sqrt(iter))*RP;
    grad = phi_rp*((residual - phi_rp'*RP).*prec); % this is rp grad
    RP = RP + rho*grad/sqrt(iter*(grad'*grad));
    % Update conditional posterior for E step
    dotRPPhi = RP'*phi_rp;
    residual = y(idx) - model_avg' - dotRPPhi';
    grad = .5*phi_wvar*((residual.^2).*prec - 1) - lambda_w*wvar;
    grad = grad/sqrt(grad'*grad); % this is wvar grad
    wvar = wvar + rho*grad/sqrt(iter);
   % end
    % 2.e. Display progress of algorithm
    error = y(idx)' - model_avg -dotRPPhi;
    mse = (iter-1)*mse/iter + mean(error(:).^2)/iter;  % Roughly approximates the training mse
    display(['Weights Iteration ' num2str(iter) ' ::: mse ' num2str(mse)]);
end

% todo aug 2 2023 - translate to octave below

if strcmp(bne_mode, 'testMeanPredOnly')
    sigW = 0;
else

% % === CALCULATE THE COVARIANCE ===
    bool_global_cov = 0; % If 1, this calculates cross correlations across model/bias vectors.
    % If 0, it still calculates correlations within paramter vectors of each model & bias
    % we do correlation within parameters as an approspaceimation to avoid getting
    % a matrispace that is not positive definite
    sigW = zeros(num_rand_feat*(num_models+1));
    for iter = 1:max(1,floor(num_obs/batch_size)-1)
        if strcmp(time_metric, 'percentOfYear')
            phi_w = sqrt(2/num_rand_feat)*cos(Zs*space((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,:)'/scale_space_w + Zt*58.0916*[cos(2*pi*time((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size))' ; sin(2*pi*time((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size))']/scale_time_w + piZ*ones(1,batch_size));
            phi_rp = sqrt(2/num_rand_feat)*cos(Zs*space((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,:)'/scale_space_rp + Zt*58.0916*[cos(2*pi*time((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size))' ; sin(2*pi*time((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size))']/scale_time_rp + piZ*ones(1,batch_size));
        else
            phi_w = sqrt(2/num_rand_feat)*cos(Zs*space((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,:)'/scale_space_w + Zt*time((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size)'/scale_time_w + piZ*ones(1,batch_size));
            phi_rp = sqrt(2/num_rand_feat)*cos(Zs*space((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,:)'/scale_space_rp + Zt*time((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size)'/scale_time_rp + piZ*ones(1,batch_size));
        end
        prec = exp(-wvar'*phi_w);
        dotWPhi = W'*phi_w;
        % catch for really big values
        dotWPhi(dotWPhi>100)=90;
        dotWPhi(dotWPhi<-100)=-90;
        softmax = exp(dotWPhi);
        softmax = softmax./repmat(sum(softmax,1),num_models,1);
        model_avg = sum(softmax.*models((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,:)',1);
        dotRPPhi = RP'*phi_rp;
        error = y((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size)' - model_avg - dotRPPhi;
        t1 = -((models((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,:)' - repmat(model_avg,num_models,1)).*softmax).^2;
        t2 = repmat(error,num_models,1).*(models((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,:)' - repmat(model_avg,num_models,1)).*softmax.*(1-2*softmax);
        for i = 1:num_models
            for j = i:num_models
                if i == j
                    sigW((i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat,(i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat) = ...
                        sigW((i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat,(i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat) ...
                             -lambda_w*eye(num_rand_feat)/floor(num_obs/batch_size) + (repmat(prec.*(t1(i,:) + t2(i,:)),num_rand_feat,1).*phi_w)*phi_w';
                elseif bool_global_cov
                    tij1 = -(models((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,i)'-model_avg).*(models((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,j)'-model_avg).*softmax(i,:).*softmax(j,:);
                    tij2 = -error.*(models((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,j)'-model_avg).*softmax(i,:).*softmax(j,:);
                    tij3 = -error.*(models((iter-1)*batch_size+1:(iter-1)*batch_size+batch_size,i)'-model_avg).*softmax(i,:).*softmax(j,:);
                    sigW((i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat,(j-1)*num_rand_feat+1:(j-1)*num_rand_feat+num_rand_feat) = ...
                        sigW((i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat,(j-1)*num_rand_feat+1:(j-1)*num_rand_feat+num_rand_feat) + ...
                         (repmat(prec.*(tij1+tij2+tij3),num_rand_feat,1).*phi_w)*phi_w';
                    sigW((j-1)*num_rand_feat+1:(j-1)*num_rand_feat+num_rand_feat,(i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat) = ...
                        sigW((j-1)*num_rand_feat+1:(j-1)*num_rand_feat+num_rand_feat,(i-1)*num_rand_feat+1:(i-1)*num_rand_feat+num_rand_feat) + ...
                         (repmat(prec.*(tij1+tij2+tij3),num_rand_feat,1).*phi_w)*phi_w';
                end
            end
        end
        sigW(num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat,num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat) = ...
            sigW(num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat,num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat) ...
            -lambda_rp*eye(num_rand_feat)/floor(num_obs/batch_size) - (repmat(prec,size(phi_rp,1),1).*phi_rp)*phi_rp';
        if bool_global_cov  %%% 7/30/2023 note: Did not update this loop for "noise" variable since bool is set to "off" for now
            for k = 1:num_models
               sigW(num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat,(k-1)*num_rand_feat+1:(k-1)*num_rand_feat+num_rand_feat) = ...
                   sigW(num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat,(k-1)*num_rand_feat+1:(k-1)*num_rand_feat+num_rand_feat) ...
                   -(1/noise)*(repmat((models(iter*batch_size+1:iter*batch_size+batch_size,k)'-model_avg).*softmax(k,:),num_rand_feat,1).*phi_w)*phi_rp';
               sigW((k-1)*num_rand_feat+1:(k-1)*num_rand_feat+num_rand_feat,num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat) = ...
                   sigW((k-1)*num_rand_feat+1:(k-1)*num_rand_feat+num_rand_feat,num_models*num_rand_feat+1:num_models*num_rand_feat+num_rand_feat) ...
                   -(1/noise)*(repmat((models(iter*batch_size+1:iter*batch_size+batch_size,k)'-model_avg).*softmax(k,:),num_rand_feat,1).*phi_rp)*phi_w';
            end
        end
    end
    % we keep only the diagonal values - within-parameter variance as an approspaceimation to avoid getting
    % a matrispace that is not positive definite
    % by not borrowing information from other parameters, our approspaceimation has
    % slightly higher uncertainty than the true uncertainty.

    %%% The following makes the covariance a diagonal matrix. The absolute
    %%% value is to fix any potential numerical issues
    sigW = diag(abs(1./diag(sigW)));

    % sigW = [];
end
