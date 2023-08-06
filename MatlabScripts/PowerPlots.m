% using the previously calculated power spectrums for both devices (SOMNO HD eco and DreamMachine)
clearvars -except delta theta alpha sigma Delta Theta Alpha Sigma Participant all_corr outlier_trials trialToDelete freq_epoched Freq_epoched all_pow All_pow;
clc;

%% scatter plots with linear regression (per frequency band)
% define dotsize for scatter plots
dotsize = 15;

% frequency bands as strings and as data variables
frequencyBands = {'Delta', 'Theta', 'Alpha', 'Sigma'};
dataVars_SHe = {delta, theta, alpha, sigma};
dataVars_DM = {Delta, Theta, Alpha, Sigma};

for freq_band = 1:4
    % Create figure based on frequency band and include participant acronym in title
    figure('Name', strcat(Participant, ' - ', frequencyBands{freq_band}))
    for channel = 1:6
        subplot(2,3, channel); % Determine order and amount of plots

        % Get data variables based on frequency band
        x = dataVars_SHe{freq_band}.trial{1, 1}(:, channel); % SOMNO HD eco
        y = dataVars_DM{freq_band}.trial{1, 1}(:, channel); % DreamMachine

        % perform robust (linear) regression
        [b,stats] = robustfit(x,y);
        slope = round(b(2), 4); % extract slope value of regression

        % define trials as outliers when their residuals (observed-fitted values)
        % are greater than 10 times the median absolute deviation
        outliers = abs(stats.resid) > 10*mad(stats.resid);

        % only keep outliers that are in fact artifacted trials (code added after visual inspection of outlier_trials) 
        if Participant == 'lbod'
           outliers(161) = 0;
        elseif Participant == 'gkhs'
            outliers([1,76,77,78,79,80,82,83]) = 0;
        elseif Participant == 'glws'
            outliers([140,141,163]) = 0;
        elseif Participant == 'ghnf'
            outliers([1, 112]) = 0;
        elseif Participant == 'bmn1'
            outliers(151) = 0;
        elseif Participant == 'gasa'
            outliers([2,6,124]) = 0;
        elseif Participant == 'gcss'
            outliers([4; 87; 88]) = 0;
        elseif Participant == 'rhbd'
            outliers([25,33]) = 0;
        end
        
        % calculate correlation coefficient excluding artifacted trials
        corr = corrcoef(x(~outliers),y(~outliers));
        % save information for each frequency band and channel into one variable
        all_corr{channel,freq_band} = round(corr(2), 4);
        outlier_trials{channel,freq_band} = find(outliers);
        all_slopes{channel,freq_band} = slope;

        % Plot outliers, non-outliers, and robust (linear) regression
        scatter(x(~outliers), y(~outliers), dotsize, 'filled', 'DisplayName', 'trials');
        hold on;
        if any(outliers)
            scatter(x(outliers), y(outliers), dotsize, 'filled', 'DisplayName', 'outliers');
            hold on;
        end
        
        % make regression line cross full window
        x_start = min(x) - 1;
        x_end = max(x) + 10000;
        x_reg = [x_start, x_end];
        y_reg = b(1)+b(2)*x_reg;
        plot(x_reg, y_reg, 'r-', 'DisplayName', 'robustfit'); % draw red regression line
        hold on;
        
        axis square;
        xlim([min(min(x,y)) max(max(x,y))])
        ylim([min(min(x,y)) max(max(x,y))])
        hold off;

        lgd = legend;
        lgd.Title.String = strcat("r = ", num2str(round(corr(2), 4)));
        lgd.Title.String = strcat("r = ", num2str(round(corr(2), 4)), ", slope = ", num2str(slope));
        lgd.Location = 'southeast';
        lgd.FontSize = 7.5;
        xlabel('SOMNO HD eco power');
        ylabel('DreamMachine power');
        title(delta.label(channel)); % labels are the same throughout all frequency bands

    end
end