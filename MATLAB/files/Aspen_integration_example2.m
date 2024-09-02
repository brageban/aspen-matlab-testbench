% Aspen Plus V14.0
% Steady-state calculation
% Uses the AspenHandler.m class

clc, clear

addpath('../utilities');

%% Check file existence

%Input .bkp or .apw file dir location
loc = fullfile(pwd,'..\..\Aspen_files\Matlab_integration_test\test_sim_matlab_1.apw')

%Check if file exists
if isfile(loc)
    disp('');
else
    disp('file_not_exist');
end

% Check admin priveliges
[status, result] = system('net session');
if status == 0
    disp('MATLAB is running with administrative privileges.');
else
    disp('MATLAB is NOT running with administrative privileges.');
end

%% Invoke the aspen COM server
Aspen = AspenHandler(loc);

%% Declare system variables
u_node = '\Data\Blocks\B1\Input\TEMP';
y_node1 = "\Data\Streams\V\Output\MOLEFRAC\MIXED\C1"; % methane
y_node2 = "\Data\Streams\V\Output\MOLEFRAC\MIXED\C2"; % ethane
y_node3 = "\Data\Streams\V\Output\MOLEFRAC\MIXED\C3"; % ethane
y_node4 = "\Data\Streams\V\Output\MOLEFRAC\MIXED\C4-1"; % n-butane
y_node5 = "\Data\Streams\V\Output\MOLEFRAC\MIXED\C4-2"; % isobutane

%% Receive data
T = -35:5:75;
xc1 = zeros(length(T),5); % Preallocate xc1 for efficiency

for i = 1:length(T)
    Aspen.SS_input(u_node, T(i)); % Set the input temperature
    xc1(i,1) = Aspen.SS_output(y_node1); % Get the output value
    xc1(i,2) = Aspen.SS_output(y_node2); % Get the output value
    xc1(i,3) = Aspen.SS_output(y_node3); % Get the output value
    xc1(i,4) = Aspen.SS_output(y_node4); % Get the output value
    xc1(i,5) = Aspen.SS_output(y_node5); % Get the output value
end
%% Plotting
figure()
plot(T, xc1, '-k');
xlabel('Temperature (°C)');
ylabel('Methane Purity (%)');
title('Methane Purity vs. Temperature');

delete(Aspen)


