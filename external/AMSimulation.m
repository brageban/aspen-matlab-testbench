function AMSimulation(block)
%%   
%% Block parameters are:
%% 1. Input file name (string wrapped in single quotes) i.e. 'SumDyn.acmf'
%%
%% 2. AM application type (string wrapped in single quotes):
%%    Aspen Custom Modeler  = 'ACM Application'
%%    Aspen Dynamics        = 'AD Application'
%%    Aspen Adsim           = 'ADS Application'
%%    Aspen Chromatography  = 'CHM Application'
%%
%% 3. Number of inputs to block (integer) i.e. 2
%%
%% 4. Backslash \ separated list of AM variable names in input port number
%%    order (string wrapped in single quotes) i.e. 'B1.T,B3.SubBlock.Flow'
%%    The variable must exist or the run will be terminated.
%%    If in a specific unit of measurement use the pipe symbol to append
%%    the units i.e. 'B1.T|K,B3.SubBlock.Flow|kmol/hr'
%%    The units of measurement must exists or the run will be terminated.
%%
%% 5. Number of outputs from block (integer) i.e. 1
%%
%% 6. Backslash \ separated list of AM variable names in output port
%%    number order (string wrapped in single quotes) i.e. 'B3.OutFlow'
%%    If in a specific unit of measurement use the pipe symbol to append
%%    the units i.e. 'B3.OutFlow|lbmol/min'
%%
%% 7. Make AM application visible during run (logical) i.e. true
%%
%% 8. Filter for variables marked as inputs/outputs (logical) i.e. true
%%
%% 9. Always open Aspen Modeler on simulink model open (logical) i.e. true
%%
setup(block);
%endfunction

%% Function: setup ===================================================
%% Abstract:
%%   Set up the S-function block's basic characteristics such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%% 
%%   C-Mex S-function counterpart: mdlInitializeSizes
%%
function setup(block)
  %disp('AMSimulation: Setup called...');
  %global AMObjects[10]
  % Setup port properties to be inherited or dynamic
  block.SetPreCompInpPortInfoToDynamic;
  block.SetPreCompOutPortInfoToDynamic;
  % Do not persist UserData in input file
  %set_param ( gcb, 'UserDataPersistent', 'off' );
  % Register parameters
  block.NumDialogPrms = 9; % Input file, Application type, #Inputs, InputVarList, #Outputs, OutputVarList, VisibleAM, FilterVars, OpenAMOnOpen
  block.DialogPrmsTunable = {'Nontunable','Nontunable','Nontunable','Nontunable','Nontunable','Nontunable','Nontunable','Nontunable','Nontunable'};
  % Register number of ports
  block.NumInputPorts  = fix(block.DialogPrm(3).Data);
  block.NumOutputPorts = fix(block.DialogPrm(5).Data);
  % Override input port properties
  for ii = 1:fix(block.DialogPrm(3).Data)
    block.InputPort(ii).DatatypeID  = 0;  %double
    block.InputPort(ii).Complexity  = 'Real';
    block.InputPort(ii).SamplingMode = 0;
    block.InputPort(ii).Dimensions = 1;
  end
  % Override output port properties
  for ii = 1:fix(block.DialogPrm(5).Data)
    block.OutputPort(ii).DatatypeID  = 0; %double
    block.OutputPort(ii).Complexity  = 'Real';
    block.OutputPort(ii).SamplingMode = 0;
    block.OutputPort(ii).Dimensions = 1;
  end

  %% -----------------------------------------------------------------
  %% Register sample times
  %% -----------------------------------------------------------------
  %  [0 offset]            : Continuous sample time
  %  [positive_num offset] : Discrete sample time
  %
  %  [-1, 0]               : Port-based sample time
  %  [-2, 0]               : Variable sample time
  block.SampleTimes = [-1, 0];

  %% -----------------------------------------------------------------
  %% Options
  %% -----------------------------------------------------------------
  % Specify if Accelerator should use TLC or call back into 
  % M-file
  block.SetAccelRunOnTLC(false);

  %% -----------------------------------------------------------------
  %% Register methods called during update diagram/compilation
  %% -----------------------------------------------------------------
  block.RegBlockMethod('CheckParameters', @CheckUserParameters);
  
  %% -----------------------------------------------------------------
  %% Register methods called at run-time
  %% -----------------------------------------------------------------
  %block.RegBlockMethod('InitializeConditions', @InitializeConditions);
  block.RegBlockMethod('Start', @Start);
  block.RegBlockMethod('Outputs', @Outputs);
  block.RegBlockMethod('SimStatusChange', @SimStatusChange);
  block.RegBlockMethod('Terminate', @Terminate);

%endfunction


%% -------------------------------------------------------------------
%% Local functions
%% -------------------------------------------------------------------

function CheckUserParameters(block)
  %% 
  %% CheckParameters:
  %%   Required         : No
  %%   Functionality    : Called in order to allow validation of
  %%                      block's dialog parameters. User is 
  %%                      responsible for calling this method
  %%                      explicitly at the start of the setup method
  %%   C-Mex counterpart: mdlCheckParameters
  %%
%endfunction

function Start(block)
  %% 
  %% Start:
  %%   Required         : No
  %%   Functionality    : Called in order to initalize state and work
  %%                      area values
  %%   C-Mex counterpart: mdlStart
  %%
  %disp('AMSimulation: Start called...');
  %last check
%   if strcmp( get_param(gcb,'Parameters'), '' )
%     error( 'AMSimulation: Blank block parameters, open configure form!' );
%   end
  if strcmp( block.DialogPrm(1).Data, '<inputfilepath>' )
    error( 'AMSimulation: Aspen Modeler input file not defined!' );
  end
  if strcmp( block.DialogPrm(4).Data, '[Undefined]' )
    error( 'AMSimulation: Aspen Modeler input variables not defined!' );
  end
  if strcmp( block.DialogPrm(6).Data, '[Undefined]' )
    error( 'AMSimulation: Aspen Modeler output variables not defined!' );
  end
  % Create instance of Aspen Modeler controller if not already loaded
  global AMControl
  if ~strcmp( class(AMControl), 'COM.AMSimulation_Control' )
    AMControl = actxserver ( 'AMSimulation.Control' );
  end
  % Persist the AM controller for other calls
  %(why does UserData get changed when you open another block?)
  %set_param( gcb, 'UserData', AMControl );
  %AMObjects(block.DialogPrm(8).Data) = AMControl;
  % Start up the AM application and set up input/output variables
  %disp('AMSimulation: Loading model...');
  try
    bRet = invoke( AMControl, 'StartRun', pwd, block.DialogPrm(1).Data, block.DialogPrm(2).Data, block.DialogPrm(3).Data, block.DialogPrm(4).Data, block.DialogPrm(5).Data, block.DialogPrm(6).Data, block.DialogPrm(7).Data );
  catch
    error( lasterr );
  end
  %disp('AMSimulation: Loaded model...');
%endfunction

function Outputs(block)
  %% 
  %% Outputs:
  %%   Required         : Yes
  %%   Functionality    : Called to generate block outputs in
  %%                      simulation step
  %%   C-Mex counterpart: mdlOutputs
  %%
  %disp(strcat('AMSimulation: Output called... ',num2str(block.CurrentTime)));
  % Get persisted AM controller
  global AMControl
  %global AMObjects[10]
  %(why does UserData get changed when you open another block?)
  %AMControl = get_param( gcb, 'UserData' );
  %AMControl = AMObjects(block.DialogPrm(8).Data); 
  %do we have a valid block stored
  if strcmp(class(AMControl),'COM.AMSimulation_Control')
    try
      % Send new input values
      invoke( AMControl, 'UpdateInputs', block.DialogPrm(1).Data );
      for ii = 1:fix(block.DialogPrm(3).Data)
        if invoke( AMControl, 'SetInputValue', ii, block.InputPort(ii).Data, block.DialogPrm(1).Data ) == false
          error( 'AMSimulation: Could not send new inputs!' );
        end
      end
      % Execute run
      if invoke( AMControl, 'Run', block.CurrentTime, block.DialogPrm(1).Data ) == false
        error( 'AMSimulation: Could not execute run!' );
      end
      % Get new output values
      for ii = 1:fix(block.DialogPrm(5).Data)
        block.OutputPort(ii).Data = invoke( AMControl, 'GetOutputValue', ii, block.DialogPrm(1).Data );
      end
    catch
      error( lasterr );
    end
  else
    error( 'AMSimulation: Invalid object in store!' );
  end
%endfunction

function SimStatusChange(block, s)
  %% 
  %% SimStatusChange:
  %%   Required         : No
  %%   Functionality    : Called when simulation goes to pause mode
  %%                      or continnues from pause mode
  %%   C-Mex counterpart: mdlSimStatusChange
  %%
%   if s == 0
%     disp('AMSimulation: Pause has been called...');
%   elseif s == 1
%     disp('AMSimulation: Continue has been called...');
%   end
%endfunction
    
function Terminate(block)
  %% 
  %% Terminate:
  %%   Required         : Yes
  %%   Functionality    : Called at the end of simulation for cleanup
  %%   C-Mex counterpart: mdlTerminate
  %%
  %disp('AMSimulation: Terminate called...');
  % Get persisted AM controller
  global AMControl
  %global AMObjects[10]
  %(why does UserData get changed when you open another block?)
  %AMControl = get_param( gcb, 'UserData' );
  %AMObjects(block.DialogPrm(8).Data) = AMControl;
  if strcmp(class(AMControl),'COM.AMSimulation_Control')
    % Shutdown AM instance
    invoke( AMControl, 'Terminate', block.DialogPrm(1).Data );
    % Delete control object if no other sessions are loaded
    if invoke( AMControl, 'SessionCount' ) == 0
      AMControl.delete
    end
  end
%endfunction
