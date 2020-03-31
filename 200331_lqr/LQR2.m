%% ACC LQR MATLAB

clear all;
clc;
%% System Specifications
T_eng = 0.460;
K_eng = 0.732;
A_f = -1/T_eng;
B_f = -K_eng/T_eng;
C_f = eye(3);
T_hw = 1.6;
Ts = 0.05;
T_total = 10;
T = T_total/Ts;
v0 = 15;

%% Create State-Space & Discretize the system

At    = [0 1 -T_hw; 0 0 -1; 0 0 A_f];
Bt    = [0; 0; B_f];
C_f   = diag([1,0,0]);
D     = zeros(3,1);
sys1  = ss(At,Bt,C_f,D);
sys2  = c2d(sys1,Ts,'zoh');
A     = sys2.A;
B     = sys2.B;
C     = sys2.C;
D     = sys2.D;

%% 
% convert state-space representation to transfer function
[b,a] = ss2tf(A,B,C,D);
sys3  = tf(b,a);
 
% W=input('if want to enter value of Q manually enter 1 else 2 = ')
% if W==1
%     Q=input('enter value of q = ')
% else
%     Q=transpose(C)*C
% end


% R=input('enter the matrix of R(no. of columns must be equal to B) = ');
% 
% Y=input('if want to enter value of N manually enter 1 else 2 = ')
% if Y==1
%     N=input('enter value of N = ')
% else
%     N=0
% end
Q = transpose(C)*C;
R = 1;
N = 0;

[K,S,e] = LQR(A,B,Q,R,N);
sys = ss(A,B,C,D);

subplot(311);
step(sys);
n = length(K);
AA = A - B * K;
for i=1:n
    BB(:,i)=B * K(i);
end

display(BB);
CC = C;
DD = D;

for i=1:n
     sys(:,i)=ss(AA,BB(:,i),CC,DD);
end

subplot(312);
step(sys(:,1));

subplot(313);
step(sys(:,2))


