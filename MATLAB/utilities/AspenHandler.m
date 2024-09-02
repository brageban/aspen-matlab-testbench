classdef AspenHandler
    properties
        version = 'Apwn.Document.40.0'; % Aspen version
        file_dir                         % Directory of the Aspen file
        Aspen                           % COM server object
        visible = true;                 % Visibility of Aspen UI (default: true)
    end
    
    methods
        % Constructor to invoke Aspen
        function obj = AspenHandler(file_path, varargin)
            % Parse optional inputs
            p = inputParser;
            addRequired(p, 'file_path', @ischar);
            addParameter(p, 'visible', true, @islogical);

            parse(p, file_path, varargin{:});

            % Assign parsed inputs to object properties
            obj.file_dir = p.Results.file_path;
            obj.visible = p.Results.visible;
            
            % Create Aspen COM server object
            try
                obj.Aspen = actxserver(obj.version);
            catch ME
                error('Error creating Aspen COM server object: %s', ME.message);
            end
            
            % Initialize Aspen from the provided file
            if isfile(obj.file_dir)
                disp(obj.file_dir)
                try
                    obj.Aspen.InitFromArchive2(obj.file_dir);
                catch ME    
                    error('Error initializing Aspen: %s', ME.message);
                end
            else
                error('Aspen file not found: %s', obj.file_dir);
            end

            % Set Aspen visibility based on the optional input
            obj.Aspen.Visible = obj.visible;
            obj.Aspen.SuppressDialogs = 1;
        end

        % Method to get steady-state output from Aspen
        function y = SS_output(obj, y_node)
            if isempty(obj.Aspen)
                error('Aspen is not initialized');
            end
            try
                node = obj.Aspen.Application.Tree.FindNode(y_node);
                y = node.Value;
            catch ME
                error('Error getting steady-state output: %s', ME.message);
            end
        end

        % Method to set steady-state input to Aspen
        function SS_input(obj, u_node, u_value)
            if isempty(obj.Aspen)
                error('Aspen is not initialized');
            end
            try
                node = obj.Aspen.Application.Tree.FindNode(u_node);
                disp([u_node, node.value])
                node.Value = u_value;
                obj.Aspen.Reinit;
                obj.Aspen.Engine.Run2;
                while obj.Aspen.Engine.IsRunning == 1
                    pause(0.5);
                end
            catch ME
                error('Error setting steady-state input: %s', ME.message);
            end
        end
        
        % Destructor to release the Aspen COM object
        function delete(obj)
            if ~isempty(obj.Aspen)
                try
                    obj.Aspen.Close;
                    obj.Aspen.Quit;
                catch ME
                    disp(['Error closing Aspen: ', ME.message]);
                end
            end
        end
    end
end
