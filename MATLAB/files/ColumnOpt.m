clc;
clear;

% Add utilities directory to MATLAB path
addpath('../utilities');

% Define location of Aspen file

loc = fullfile('..', '..', 'Aspen_files', 'Distillation_column', 'ethanol_water_distillation.apw');

% Instantiate AspenHandler with the Aspen file location
aspen = AspenHandler(loc);

% Input and output nodes
Feed_inlet = '\Data\Blocks\COLUMN\Input\FEED_STAGE';
xDL_node = '\Data\Streams\D\Output\MOLEFRAC\MIXED\ETHANOL';
xBH_node = '\Data\Streams\B\Output\MOLEFRAC\MIXED\WATER';

% FeedStage values to iterate over
FeedStage = 10:40;
xDL = zeros(size(FeedStage));
xBH = zeros(size(FeedStage));

% Loop to interact with Aspen and retrieve valuess
for i = 1:length(FeedStage)
    aspen.SS_input(Feed_inlet, FeedStage(i));
    xDL(i) = aspen.SS_output(xDL_node);
    xBH(i) = aspen.SS_output(xBH_node);
end

% Display results
disp('xDL values:');
disp(xDL);

disp('xBH values:');
disp(xBH);

% Clean up
delete(aspen);
