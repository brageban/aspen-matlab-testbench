% Aspen Plus V14.0
% Steady-state calculation
% Uses the AspenHandler.m class

clc, clear

addpath('../utilities');

% Check file existence
%Input .bkp or .apw file dir location
loc = fullfile(pwd,'..\..\Aspen_files\Ethyl Benzene\Ethyl Benzene\EB.apw')

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

% Invoke the aspen COM server
Aspen = AspenHandler(loc);

benzene_feed_0 = Aspen.SS_output("\Data\Streams\S1\Input\TOTFLOW");
ethylene_feed_0 = Aspen.SS_output("\Data\Streams\S4\Input\TOTFLOW");


% Declare system variables
u_node1 = "\Data\Streams\S1\Input\TOTFLOW";
u_node2 = "\Data\Streams\S4\Input\TOTFLOW";
y_node1 = "\Data\Streams\C1-D\Output\MOLEFRAC\MIXED\ETHYLENE"; % ethene
y_node2 = "\Data\Streams\C1-D\Output\MASSFLOW\MIXED\BENZENE"; % benzene

% Receive data
f1 = benzene_feed_0 %* [0.99:0.01:1.01];
f2 = ethylene_feed_0 %* [0.99:0.01:1.01];
xc1 = zeros(length(f1),2);


for i = 1:length(f1)
    Aspen.SS_input(u_node1, f1(i)); % Set the ethylene
    for j = 1:length(f2)
        Aspen.SS_input(u_node2, f2(j)); % Set the input temperature

        xc1(i,1) = Aspen.SS_output(y_node1); % Get the output value
        xc1(i,2) = Aspen.SS_output(y_node2); % Get the output value
    end
end

   
% Plotting
figure()
plot(T, xc1, '-k');
xlabel('x');
ylabel('y');
title('Methane Purity vs. Temperature');

u_node1 = benzene_feed_0;
u_node2 = ethylene_feed_0;

delete(Aspen)


