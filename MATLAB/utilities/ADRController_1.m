% Translated from c-code by ChatGPT 2024.06.13 
% sign: Brage Bang
% /**
%  * @file adrc.c
%  * @author Simen Bjerkestrand (simen.bjerkestran@propusentnu.no)
%  * @brief First-Order Active Disturbance Rejection Controller (ADRC).
%  * @version 0.1
%  * @date 2024-05-11
%  *
%  * @copyright Copyright Propulse NTNU (c) 2024
%  *
%  */

classdef ADRCController_1
    properties
        x1_hat          % State estimation
        x2_hat
        x3_hat
        x1_hat_prev
        x2_hat_prev
        x3_hat_prev
        out             % Output
        limMin          % Minimum output limit
        limMax          % Maximum output limit
        order           % Order of the controller
        t_settle        % Settling time
        k_eso           % Extended state observer gain
        b0              % Control gain
        w_cl            % Closed-loop bandwidth
        Kp              % Proportional gain
        Kd              % Derivative gain
        z_eso           % Observer dynamics parameter
        Ad11            % State-space matrix
        Ad12
        Ad13
        Ad21
        Ad22
        Ad23
        Ad31
        Ad32
        Ad33
        Bd1
        Bd2
        Bd3
        Ld1
        Ld2
        Ld3
    end
    
    methods
        % Constructor
        function obj = ADRCController_1(dt, b0, w_cl, k_eso, limMin, limMax, order)
            obj.x1_hat = 0.0;
            obj.x2_hat = 0.0;
            obj.x3_hat = 0.0;
            obj.x1_hat_prev = 0.0;
            obj.x2_hat_prev = 0.0;
            obj.x3_hat_prev = 0.0;
            obj.out = 0.0;
            obj.limMin = limMin;
            obj.limMax = limMax;
            obj.order = order;
            obj.t_settle = 4 / w_cl;
            obj.k_eso = k_eso;
            obj.b0 = b0;
            obj.w_cl = w_cl;
            
            if order == 1
                s_cl = -4 / obj.t_settle;
                obj.Kp = -2 * s_cl;
                s_eso = obj.k_eso * s_cl;
                obj.z_eso = exp(s_eso * dt);
                obj.Ad11 = obj.z_eso^2;
                obj.Ad12 = dt + dt * (obj.z_eso^2 - 1);
                obj.Ad21 = -(obj.z_eso - 1)^2 / dt;
                obj.Ad22 = 1 - (obj.z_eso - 1)^2;
                obj.Bd1 = dt * obj.b0 + dt * obj.b0 * (obj.z_eso^2 - 1);
                obj.Bd2 = -obj.b0 * (obj.z_eso - 1)^2;
                obj.Ld1 = 1 - obj.z_eso^2;
                obj.Ld2 = (1 - obj.z_eso)^2 / dt;
            elseif order == 2
                t_settle = 6 / obj.w_cl;
                s_cl = -6 / t_settle;
                obj.Kp = s_cl^2;
                obj.Kd = -1 * s_cl;
                s_eso = obj.k_eso * s_cl;
                obj.z_eso = exp(s_eso * dt);
                obj.Ad11 = obj.z_eso^3;
                obj.Ad12 = dt + dt * (obj.z_eso^3 - 1);
                obj.Ad13 = dt^2 * (obj.z_eso^3 - 1) / 2 + dt^2 / 2;
                obj.Ad21 = -3 * (obj.z_eso - 1)^2 * (obj.z_eso + 1) / (2 * dt);
                obj.Ad22 = 1 - 3 * (obj.z_eso - 1)^2 * (obj.z_eso + 1) / 2;
                obj.Ad23 = dt - 3 * dt * (obj.z_eso - 1)^2 * (obj.z_eso + 1) / 4;
                obj.Ad31 = (obj.z_eso - 1)^3 / dt^2;
                obj.Ad32 = (obj.z_eso - 1)^3 / dt;
                obj.Ad33 = (obj.z_eso - 1)^3 / 2 + 1;
                obj.Bd1 = obj.b0 * dt^2 / 2 + obj.b0 * dt^2 * (obj.z_eso^3 - 1) / 2;
                obj.Bd2 = obj.b0 * dt - 3 * obj.b0 * dt * (obj.z_eso - 1)^2 * (obj.z_eso + 1) / 4;
                obj.Bd3 = obj.b0 * (obj.z_eso - 1)^3 / 2;
                obj.Ld1 = 1 - obj.z_eso^3;
                obj.Ld2 = 3 * (obj.z_eso - 1)^2 * (obj.z_eso + 1) / (2 * dt);
                obj.Ld3 = -obj.z_eso^3 / dt^2;
            end
        end
        
        % Update the ADRC controller
        function obj = updateESO(obj, setpoint, measurement, dt, derivative)
            if obj.order == 1
                obj.x1_hat = obj.Ad11 * obj.x1_hat_prev + obj.Ad12 * obj.x2_hat_prev + obj.Bd1 * obj.out + obj.Ld1 * measurement;
                obj.x2_hat = obj.Ad21 * obj.x1_hat_prev + obj.Ad22 * obj.x2_hat_prev + obj.Bd2 * obj.out + obj.Ld2 * measurement;
                obj.x1_hat_prev = obj.x1_hat;
                obj.x2_hat_prev = obj.x2_hat;
            elseif obj.order == 2
                obj.x1_hat = obj.Ad11 * obj.x1_hat_prev + obj.Ad12 * obj.x2_hat_prev + obj.Ad13 * obj.x3_hat_prev + obj.Bd1 * obj.out + obj.Ld1 * measurement;
                obj.x2_hat = obj.Ad21 * obj.x1_hat_prev + obj.Ad22 * obj.x2_hat_prev + obj.Ad23 * obj.x3_hat_prev + obj.Bd2 * obj.out + obj.Ld2 * measurement;
                obj.x3_hat = obj.Ad31 * obj.x1_hat_prev + obj.Ad32 * obj.x2_hat_prev + obj.Ad33 * obj.x3_hat_prev + obj.Bd3 * obj.out + obj.Ld3 * measurement;
                obj.x1_hat_prev = obj.x1_hat;
                obj.x2_hat_prev = obj.x2_hat;
                obj.x3_hat_prev = obj.x3_hat;
            end
        end
        
        % Update the ADRC controller
        function obj = update(obj, setpoint, measurement, dt, derivative)
            obj = obj.updateESO(setpoint, measurement, dt, derivative);
            if obj.order == 1
                obj.out = (obj.Kp * (setpoint - obj.x1_hat) - obj.x2_hat) / obj.b0;
            elseif obj.order == 2
                obj.out = (obj.Kp * (setpoint - obj.x1_hat) - obj.Kd * obj.x2_hat - obj.x3_hat) / obj.b0;
            end
            
            if obj.out > obj.limMax
                obj.out = obj.limMax;
            elseif obj.out < obj.limMin
                obj.out = obj.limMin;
            end
        end
    end
end
