function Q = galoisReductionMatrix(P)
%galoisReductionMatrix Generates a reduction matrix based on the given polynomial
%   based on the first couple of elements in the Galois Field
m = size(P,2);

field = zeros(m-1, m);
field(1,:) = P;

for i = 2:m-1
    % Multiply by polynomial x^1
    temp = conv(field(i-1,:), [1 0]);
    % This will become m+1 long
    sig = temp(1);
    temp = temp(2:end);
    
    % If the multiplication results in an element 
    % that is too big for the field, it must be 
    % reduced by the characteristic polynomial
    if sig == 1
        temp = bitxor(temp, P);
    end
    field(i,:) = temp;
end

% The reduction matrix must be flipped
Q = fliplr(field);

end

