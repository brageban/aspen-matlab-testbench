

%  * @file adrc_2.m
%  * @author Brage Bang (brage.bang@propusentnu.no)
%  * @brief linear First-Order Active Disturbance Rejection Controller (ADRC).
%  * Adapted from Herbst and Madonski (2023) https://doi.org/10.1007/s11768-023-00127-0
%  * @version 0.1
%  * @date 2024-06-14
%  *
%  * @copyright Copyright Propulse NTNU (c) 2024
%  *
%  */


classdef ADRCController_2
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



    end
end

