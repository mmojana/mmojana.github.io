% The MIT License (MIT)
% 
% Copyright (c) 2015 Marco Mojana
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.


% === Input data ===============================================================

vpx = [-89 71 1]';
vpy = [947 104 1]';
c = [31 -33 1]';
w = 960;
z = 1;
d = 146;

% === Processing ===============================================================
C = zeros(3, 4);
C(:, 1) = vpx;
C(:, 2) = vpy;
C(:, 4) = c;

f = sqrt(-vpx(1:2)' * vpy(1:2));
beta = 2 * atan(w / (2 * f));
betadeg = beta / pi * 180

p = diag([1 1 -1/f]);
RRt = inv(p) * C;
RRt(:, 1) = RRt(:, 1) / norm(RRt(:, 1));
RRt(:, 2) = RRt(:, 2) / norm(RRt(:, 2));
RRt(:, 3) = cross(RRt(:, 1), RRt(:, 2));
R = RRt(:, 1:3);

theta = zeros(3, 1);
theta(3) = atan2(R(1, 2), R(1, 1));
theta(2) = asin(-R(1, 3));
theta(1) = atan2(R(2, 3), R(3, 3));
thetadeg = theta / pi * 180

C = p * RRt;

function e = scale_err(s, C, z, d, c)
	Cprime = C;
	Cprime(:, 4) = Cprime(:, 4) * s(1);
	hProj = Cprime * [0 0 z 1]';
	e = abs(d - norm(c(1:2) / c(3) - hProj(1:2) / hProj(3)));
end

sOpt = fsolve(@(s) scale_err(s, C, z, d, c), [0]);

C(:, 4) = C(:, 4) * sOpt;
RRt = inv(p) * C;

t = -inv(R) * RRt(:, 4)

% === Result check =============================================================
printf("Decomposition error:\n");
P = [1 0 0 0; 0 1 0 0; 0 0 -1/f 0];
T = [1 0 0 -t(1); 0 1 0 -t(2); 0 0 1 -t(3); 0 0 0 1];
Rx = [1 0 0 0;0 cos(-theta(1)) -sin(-theta(1)) 0; 0 sin(-theta(1)) cos(-theta(1)) 0; 0 0 0 1];
Ry = [cos(-theta(2)) 0 sin(-theta(2)) 0; 0 1 0 0; -sin(-theta(2)) 0 cos(-theta(2)) 0; 0 0 0 1];
Rz = [cos(-theta(3)) -sin(-theta(3)) 0 0; sin(-theta(3)) cos(-theta(3)) 0 0; 0 0 1 0; 0 0 0 1];
C - P * Rx * Ry * Rz * T

printf("X axis vanishing point error:\n");
norm(cross(vpx, C(:, 1)))

printf("Y axis vanishing point error:\n");
norm(cross(vpy, C(:, 2)))

printf("Origin point error:\n");
norm(cross(c, C(:, 4)))

printf("Scale error:\n");
pz = C * [0 0 z 1]';
d - norm(c(1:2) / c(3) - pz(1:2) / pz(3))
