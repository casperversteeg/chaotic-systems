%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CREDITS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Chaos
%   Written by: Casper Versteeg
%   Lynk World, Inc
%   2021/09/29
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CREDITS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; close all; clc; addpath(genpath("."));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%INITIALIZE VARIABLES%%%%%%%%%%%%%%%%%%%%%%%%

set(0, "defaultTextInterpreter","latex");
set(0, "defaultAxesTickLabelInterpreter", "latex");

g           = 9.81;         % Gravitational acceleration
t_end       = 5;            % Total simulation runtime
dt          = 1e-3;         % Sampling timestep
t_plot      = 0:dt:t_end;   % Plot times
mn          = [2 0.1];      % Constants [m, n] for boundary equation
Re          = 0.99;         % Coefficient of restitution 0 <= Re <= 1

numBalls    = 10;           % Number of balls to simulate
icDelta     = 0.0001;       % Relative difference in initial condition

% Animation options
plot_step   = 10;           % How many steps from t_plot to show at once
expAnim     = false;        % Export to video file (memory intensive!)
expFrames   = false;        % Export animation frames (memory intensive!)

% Evolution equation and ODE solver options
d2x         = @(t, x) [x(3); x(4); 0; -g];
opt         = odeset('Event', @(t, x) collisionEvent(t, x, mn), ...
                'MaxStep', dt, 'AbsTol', 1e-10, 'RelTol', 1e-8);

% Plot colorings
C           = colormap('jet'); close;
cinx        = ceil(256 * linspace(eps, 1, numBalls));
            
% Output structures
soln        = struct('IC', [], 't', [], 'x', [], 't_plot', [], 'x_plot', []);
frames      = struct('cdata', [], 'colormap', []);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%END INITIALIZE%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up figure and axes
F1 = figure;
set(F1, 'Units', 'pixels', 'Color', 'white', ...
    'OuterPosition', [50,50,1800,1800*9/16]);
ax1 = axes(F1); hold(ax1, 'on'); grid(ax1, 'on'); axis(ax1, 'equal');
ax1.XLim = 1.1*[-1 1]; ax1.YLim = 1.1*[-1 1];
xlabel(ax1, '$x$'); ylabel(ax1, '$y$');
title(ax1, sprintf(strcat('%d Balls, $\\Delta x = 10^{-4}$,',...
    '~~~$e_r = %.2f$,~~~$m = %.1f$, $n = %.1f$'),...
    numBalls, Re, mn(1), mn(2)), 'FontSize', 14);
P = gobjects(1, 2*numBalls);

% Plot the enclosure boundary
fimplicit(ax1, @(x, y) boundaryEq(x, y, mn), [-1 1], 'k', ...
    'MeshDensity', 512);

% Text annotations in plot
T = text(ax1, -1, 1, '', 'FontSize', 14, 'VerticalAlignment', 'bottom');
A = annotation('textarrow', 'Position', [0.7, 0.9, -0.05, -0.05], ...
    'FontSize', 14, 'Interpreter', 'latex', 'String', '$|x|^m + |y|^n = 1$');

% Compute solution for each ball
icOffset    = icDelta * linspace(-numBalls/2, numBalls/2, numBalls);
for i = 1:numBalls
    % Create initial condition and solve evolution equation (ode45)
    soln(i).IC = [0.2 + icOffset(i); 0.5; 0.; 0];
    [t, x] = enclosureBouncing(d2x, t_end, soln(i).IC, mn, opt, Re);
    soln(i).t = t; 
    soln(i).x = x;
    % Resample solution data so balls appear to move at same rate
    soln(i).t_plot = t_plot;
    soln(i).x_plot(1,:) = interp1(t, x(1,:), t_plot, 'pchip');
    soln(i).x_plot(2,:) = interp1(t, x(2,:), t_plot, 'pchip');
    % Initialize animation plots
    P(i) = plot(ax1, soln(i).x_plot(1,1), soln(i).x_plot(2,1),...
        'Color', C(cinx(i), :));
    P(i+numBalls) = plot(ax1, soln(i).x_plot(1,1), soln(i).x_plot(2,1),...
        'Color', C(cinx(i), :), 'Marker', '.', 'MarkerSize', 10);
end

% Animate solution by updating plot x and y data for each ball
fr = 1;
for i = 1:plot_step:length(t_plot)
    for j = 1:numBalls
        P(j).XData = soln(j).x_plot(1, 1:i);
        P(j).YData = soln(j).x_plot(2, 1:i);
        P(j+numBalls).XData = soln(j).x_plot(1, i);
        P(j+numBalls).YData = soln(j).x_plot(2, i);
    end
    T.String = sprintf('\\texttt{t = %.3f}', t_plot(i));
    drawnow;
    
    % Store frames in array if exporting animation
    if expAnim || expFrames
        frames(fr) = getframe(F1);
        fr = fr + 1;
    end
end

if expAnim
    video = VideoWriter('BouncingBalls.avi','Uncompressed AVI');
    video.FrameRate = 30;
    open(video);
    writeVideo(video, frames);
    close(video);
elseif expFrames
    for i = 1:length(frames)
        im = frame2im(frames(i));
        imwrite(im, sprintf('img/BouncingBalls%04d.png', i-1));
    end
end

% Collision event equation for ODE solver
function [VALUE, ISTERMINAL, DIRECTION] = collisionEvent(~, y, mn)
    VALUE = boundaryEq(y(1), y(2), mn);
    ISTERMINAL = 1;
    DIRECTION = 1;
end

