function [bdy, dbdy] = boundaryEq(x, y, mn)
    bdy = abs(x)^mn(1) + abs(y)^mn(2) - 1;
    dbdy = -sign(x)*sign(y)*(mn(1)*abs(x)^(mn(1)-1))/(mn(2)*abs(y)^(mn(2)-1));
end