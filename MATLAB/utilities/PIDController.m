classdef PIDController
    properties
        Kc              % Controller gain
        tau_I           % Integral time constant
        tau_D           % Derivative time constant
        T               % Sampling time
        limMin          % Minimum output limit
        limMax          % Maximum output limit
        integrator      % Integrator term
        prevError       % Previous error
        derivative      % Derivative term
        state           % State Vector from system output (x_n)
        u_FF            % Feed-forward input
        prevMeasurement % Previous measurement (y_{n-1})
        input           % Input to system (output from controller)
        init            % Initial output
        params          % Parameters for the feed-forward model
        modelFunc       % Model function handle for feed-forward
    end
    
    methods
        % Constructor
        function obj = PIDController(Kc, tau_I, tau_D, T, limMin, limMax, params, modelFunc)
            obj.Kc = Kc;
            obj.tau_I = tau_I;
            obj.tau_D = tau_D;
            obj.T = T;
            obj.limMin = limMin;
            obj.limMax = limMax;
            obj.params = params;
            obj.modelFunc = modelFunc; % make it so this (feed-forward controller) is toggleable
            obj = obj.initialize();
        end
        
        % Initialize the PID controller
        function obj = initialize(obj)
            obj.integrator = 0.0;
            obj.prevError = 0.0;
            obj.derivative = 0.0;
            obj.prevMeasurement = 0.0;
            obj.state = 0;
            obj.input = 0.0;
            obj.init = obj.input;
        end
        
        % Update the discrete PID controller
        function input = update(obj, setpoint, measurement, state)
            % Update the state
            obj.state = state;
            
            % Calculate the feed-forward input using the external model function
            obj.u_FF = obj.modelFunc(obj.state, obj.params);
            
            % Error signal
            error = setpoint - measurement;
            
            % Proportional term
            proportional = obj.Kc * error;
            
            % Integral term
            obj.integrator = obj.integrator + (obj.Kc * obj.T) / obj.tau_I * error;
            
            % Derivative term (using backward-Euler with derivative on error)
            obj.derivative = obj.Kc * obj.tau_D * (error - obj.prevError) / obj.T;
            
            % Compute system input and apply limits
            obj.input = proportional + obj.integrator + obj.derivative + obj.u_FF;
            
            if obj.input > obj.limMax
                % Anti-wind-up for over-saturated output
                obj.integrator = obj.integrator + (obj.limMax - obj.input);
                obj.input = obj.limMax;
            elseif obj.input < obj.limMin
                % Anti-wind-up for under-saturated output
                obj.integrator = obj.integrator + (obj.limMin - obj.input);
                obj.input = obj.limMin;
            end
            
            % Store error and measurement for later use
            obj.prevError = error;
            obj.prevMeasurement = measurement;
            
            % Return controller output
            input = obj.input;
        end
    end
end
