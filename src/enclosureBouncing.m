function [t, x] = enclosureBouncing(eqx, t_end, ic, mn, opt, re)
    if nargin < 6
        re = 1;
    end
    x = ic; t = 0;
    while t_end > t(end)
        soln = ode45(eqx, [t(end), t_end], ic, opt);
        t = [t, soln.x(2:end)];
        x = [x, soln.y(:, 2:end)];
        ic = x(:,end);
        [~, dbnd] = boundaryEq(ic(1), ic(2), mn);
        ic(3:4) = re * reflect(ic(3:4), dbnd);
    end
end