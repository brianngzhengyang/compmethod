function random_numbers = lcg(seed, n)
    a = 1664525;
    c = 1013904223;
    m = 2^32;
    
    random_numbers = zeros(1, n);
    random_numbers(1) = mod(a * seed + c, m);
    
    for i = 2:n
        random_numbers(i) = mod(a * random_numbers(i-1) + c, m);
    end
    
    random_numbers = random_numbers / m; % Scale to [0, 1)
end