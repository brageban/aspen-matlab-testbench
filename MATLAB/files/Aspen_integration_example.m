% Aspen Plus V14.0
% Steady-state calculation

clc, clear

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

%Invoke the aspen COM server
Aspen = actxserver('Apwn.Document.40.0');
%disp(Aspen.version)
invoke(Aspen) % Method list for COM server (COM.Apwn_Document_40_0) 
Aspen.InitFromArchive2(loc);
Aspen.Visible = 1;
Aspen.SuppressDialogs = 1;

% https://se.mathworks.com/matlabcentral/fileexchange/69464-aspen-plus-matlab-link/
Aspen.Engine.Run2(1); % Run the simulation
while Aspen.Engine.IsRunning == 1 % 1 --> If Aspen is running; 0 ---> If Aspen stop.
    pause(0.5);
end

%% Receive data
T = 15:25;
j = 1;
for i = 1:length(T)
    Aspen.Application.Tree.FindNode('\Data\Blocks\B1\Input\TEMP').value = T(i); % Temperature change
    Aspen.Reinit; % Reinit simulation
    Aspen.Engine.Run2; %Run the simulation. (1) ---> Matlab isnt busy; (0) Matlab is Busy;
    node = Aspen.Application.Tree.FindNode("\Data\Streams\V\Output\MOLEFRAC\MIXED\C1").value;
    xc1(j) = node;
    time = 1;
    j = j+1;
end
%% Plotting
figure()
plot(T, xc1, 'ok');
xlabel('Temperature (°C)');
ylabel('Methane Purity (%)');
title('Methane Purity vs. Temperature');

Aspen.Close;
Aspen.Quit;


% Linearize Plant Using Aspen Plus Control Design Interface
% https://se.mathworks.com/help/mpc/ug/design-and-cosimulate-control-of-high-fidelity-distillation-tower-with-aspen-plus-dynamics.html
% 
% Step 1: Add a script to the APD model under the Flowsheet folder. In this example, 
% the script name is CDI_Calcs (as shown above) and it contains the following APD commands:
% 
% Set Doc = ActiveDocument
% set CDI = Doc.CDI
% CDI.Reset
% CDI.AddInputVariable "blocks(""B1"").condenser(1).QR"
% CDI.AddInputVariable "blocks(""B1"").QrebR"
% CDI.AddInputVariable "blocks(""B1"").Reflux.FmR"
% CDI.AddInputVariable "streams(""2"").FmR"
% CDI.AddInputVariable "streams(""3"").FmR"
% CDI.AddInputVariable "streams(""1"").FR"
% CDI.AddOutputVariable "blocks(""B1"").Stage(1).P"
% CDI.AddOutputVariable "blocks(""B1"").Stage(1).Level"
% CDI.AddOutputVariable "blocks(""B1"").SumpLevel"
% CDI.AddOutputVariable "streams(""2"").Zmn(""TOLUENE"")"
% CDI.AddOutputVariable "streams(""3"").Zmn(""BENZENE"")"
% CDI.Calculate
% 
% Step 2: Initialize the APD model to the nominal steady-state condition.
% 
% Step 3: Invoke the script, which generates the following text files:
% 
% cdi_A.dat, cdi_B.dat, cdi_C.dat define the A, B, and C matrices of a standard continuous-time LTI state-space model. 
% D matrix is zero. The A, B, C matrices are sparse matrices.
% 
% cdi_list.lis lists the model variables and their nominal values.
% 
% cdi_G.dat defines the input/output static gain matrix at the nominal condition. 
% The gain matrix is also a sparse matrix.