clc;
clear;

% Add utilities directory to MATLAB path
addpath('../utilities');

% Define location of Aspen file

loc = fullfile(pwd,'..', '..', 'Aspen_files', 'Distillation_column', 'methanol_water_distillation.apw');

% Instantiate AspenHandler with the Aspen file location
aspen = AspenHandler(loc);

% Input nodes 
Feed_inlet = "\Data\Blocks\COLUMN\Input\FEED_STAGE\S5";
Reb_node = "\Data\Blocks\COLUMN\Output\REB_DUTY";

% Output nodes
xDL_node = '\Data\Streams\D\Output\MOLEFRAC\MIXED\METHANOL';
xBH_node = '\Data\Streams\B\Output\MOLEFRAC\MIXED\WATER';

% Input values
Reb_init = aspen.SS_output(Reb_node);
Reb = Reb_init.*(0.9:0.05:1.1);
FeedStage = 10:36;

disp(length(FeedStage(1,:)))
% Output arrays
xDL = zeros(length(FeedStage(1,:)),length(Reb(1,:)));
xBH = zeros(length(FeedStage(1,:)),length(Reb(1,:)));

% Loop to interact with Aspen and retrieve values
for i = 1:length(FeedStage)
    aspen.SS_input(Feed_inlet, FeedStage(i));
    xDL(i) = aspen.SS_output(xDL_node);
    xBH(i) = aspen.SS_output(xBH_node);
    % for j = 1:length(Reb)
    %     aspen.SS_input(Reb_node, Reb(j))
    %     xDL(i,j) = aspen.SS_output(xDL_node);
    %     xBH(i,j) = aspen.SS_output(xBH_node);
    % end
end

% Display results
disp('xDL values:');
disp(xDL);

disp('xBH values:');
disp(xBH);

% Plotting
figure()
yscale log
plot(FeedStage, xDL, '.k');
hold on
plot(FeedStage, xBH, '-.g');
hold on


xlabel('Feed Stage');
ylabel('Purity (%)');

% Clean up
delete(aspen);
