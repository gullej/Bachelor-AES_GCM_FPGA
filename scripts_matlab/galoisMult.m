function c = galoisMult(a,b, P)
%galoisMult Multiplies a with b
%   Makes sure c can be represented within
%   a finite field based polynomial P

m = size(P,2)-1; 

c__ = mod(conv(a, b),2);
[~,r] = deconv(c__, P);
c_ = mod(r,2);

c = c_(m:end);

end

