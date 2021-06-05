function Q = galoisReductionMatrix(P)
%galoisReductionMatrix Generates a reduction matrix based on the given polynomial
%   based on the first couple of elements in the Galois Field
m = size(P,2);

field = zeros(m-1, m);
field(1,:) = P;

for i = 2:m-1
    temp = conv(field(i-1,:), [1 0]);
    sig = temp(1);
    temp = temp(2:end);
    
    if sig == 1
        temp = bitxor(temp, P);
    end
    field(i,:) = temp;
end

Q = fliplr(field);

end

