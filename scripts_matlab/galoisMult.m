function c = galoisMult(a,b, P)
%galoisMult Multiplies a with b
%   Makes sure c can be represented within
%   a finite field based polynomial P

m = size(P,2)-1; 

% conv works as polynomial multiplication
c__ = mod(conv(a, b),2);
% deconv works as polynomial division
% We are only interested in the remainder
[~,r] = deconv(c__, P);
% Modulo
c_ = mod(r,2);

% only output the needed elements, conv added a few
c = c_(m:end);

end

