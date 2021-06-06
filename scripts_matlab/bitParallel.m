clearvars;

% The characteristic polynomial of GCM, without the leading element
P = [zeros(1, 120) 1 0 0 0 0 1 1 1];
m = size(P,2);

% Forming the reduction matrix
Q = galoisReductionMatrix(P);

%%
% Symbolics, so as to see all the ANDs and XORs needed
A = fliplr(sym('A%d', [1 m]));
B = fliplr(sym('B%d', [1 m])).';

% Getting the two Toeplitz matrices ready
L = sym(zeros(m, m));
U = sym(zeros(m-1, m));


%%
% Generating L, the lower triangle matrix
for i = 1:m
    L(i,:) = [fliplr(A(1,1:i)) zeros(1,m-i)];
end

%%
% Generating U, the upper triangle matrix
for i = 1:m-1
    U(i,:) = [zeros(1,i) fliplr(A(i+1:m))];
end

%%
d = L * B;
e = U * B;

%%
c = d + Q.' * e;
