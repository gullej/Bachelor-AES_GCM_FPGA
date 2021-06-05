clearvars;

P = [zeros(1, 120) 1 0 0 0 0 1 1 1];
m = size(P,2);

Q = galoisReductionMatrix(P);

%%
A = fliplr(sym('A%d', [1 m]));
B = fliplr(sym('B%d', [1 m])).';

L = sym(zeros(m, m));
U = sym(zeros(m-1, m));


%%
for i = 1:m
    L(i,:) = [fliplr(A(1,1:i)) zeros(1,m-i)];
end

%%
for i = 1:m-1
    U(i,:) = [zeros(1,i) fliplr(A(i+1:m))];
end

%%
d = L * B;
e = U * B;

%%
C = fliplr(d + Q.' * e);
