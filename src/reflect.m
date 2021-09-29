function w = reflect(v, m)
    R = 1/(1+m^2) * [1-m^2, 2*m; 2*m, m^2-1];
    w = R * v;
end