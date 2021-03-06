%% Stability analysis for ACC system
% Given a set of linearized system matrices, this code determines the
% terminal set X_f which guarantees asymptotic stability. Finally, the
% value of X_N (calygraph X) can be be determined for a given prediction
% horizon N

%%
clc
clear
addpath('Code/');

disp('------------------------------------------------------------------');
disp('          STABILITY ANALYSIS OF ACC');
disp('');
disp('------------------------------------------------------------------');

%% INITIALIZATION
fprintf('\tinitializing ... \n');
% DEFINE CONSTANTS
T_eng = 0.460;
K_eng = 0.732;
T_brk = 0.193;
K_brk = 0.979;
T_s   = 0.05;
T_hw  = 1.3;
model = init_model(T_eng,K_eng,T_hw);

% DISCRETIZE SYSTEM
        
h = T_s;            % sampling time (sec)
sysd = c2d(model,h); % convert to disrete-time system
Ad = sysd.A;
Bd = sysd.B;
Cd = sysd.C;
fprintf('\tdone!\n');

%% DETERMINE OPTIMAL LQR GAIN FOR MPC COST FUNCTION
fprintf('\tdetermining LQR optimal control action ... \n');

Q = 10*eye(size(Ad));           % state quadratic cost 
R = 0.1*eye(length(Bd(1,:)));   % input quadratic cost

[X,L,K_LQR] = dare(Ad,Bd,Q,R);  % determine LQR gain for unconstrained system

A_K = Ad-Bd*K_LQR;              % closed-loop LQR system
eigvals_A_K = eig(A_K);         % determine closed-loop eigenvalues

fprintf('\tdone!\n');
%% DETERMINE INVARIANT ADMISSIBLE SET X_f
fprintf('\testimating X_f invariant set \n');

dim.nx = 3;     %
dim.nu = 1;     %

u_limit = 1;    % bound on control inputs
x_limit = 1;    % bound on states

fprintf('\t - defining state and input constraints \n');
Fu = kron(eye(dim.nu),[1; 1]);
Fx = kron(eye(dim.nx),[1; 1]);

fu = [-3 5 0];
fx = [0,0,0;2,0,0;0,0,0;0,2.5,0;0,0,15;0,0,40];

f = [fu; fx];
F = blkdiag(Fu,Fx);

s = size(F,1);

C_aug = [K_LQR; eye(dim.nx)];

% DETERMINE MAXIMUM INVARIANT SET X_f

[Xf_set_H,Xf_set_h] = max_output_set(A_K,K_LQR,1,x_limit*ones(3,1));

fprintf('\tSuccesfully constructed terminal set X_f. Plotting it in 3D...\n');
% plot3(Xf_set_H(:,1),Xf_set_H(:,2),Xf_set_H(:,3));
% axis([-1 1 -1 1 -1 1]);
%% CHECK CONSTRAINT

% given X_f calculated before, we can test if a given state x0 is within
% this set or not. This is done here:

% state x0
x0 = [0 0 15]'; % <-- state values

% check if the x-location is within X_f
inSet = all(Xf_set_H*x0 <= Xf_set_h);
if inSet == 1
    disp('Congrats! Your x-location is within Xf');
else
    disp('Not within Xf!')
end
% TEST IF MPC LAW GUIDES TOWARDS X_f IN N-STEPS

% Having constructed X_f, we empirically construct a state X_N (calygraph X) 
% to determine which states can be steered to the terminal set X_f in N 
% steps.

fprintf('\tDetermining X_N emperically for different Beta values ...\n');

N = 20;                     % prediction horizon
fprintf('\t - N = %i (prediction horizon) \n',N);

x = zeros(dim.nx,N+1);      % state trajectory

% initial state
x0 = [0 0 15]';
x(:,1) = x0;

% tuning weights
Q = 10*eye(dim.nx);         % state cost
R = 0.1*eye(dim.nu);        % input cost

% terminal cost = unconstrained optimal cost (Lec 5 pg 6)
[S,~,~] = dare(Ad,Bd,Q,R);  % terminal cost % OLD: S = 10*eye(size(A));

% determine prediction matrices
Qbar = kron(Q,eye(N));
Rbar = kron(R,eye(N));
Sbar = S;

LTI.A = Ad;
LTI.B = Bd;
LTI.C = Cd;

dim.N = N;
dim.nx = size(Ad,1);
dim.nu = size(Bd,2);
dim.ny = size(Cd,1);

[P,Z,W] = predmodgen(LTI,dim);
             
% define input constraints

lb = -3*ones(4*N,1);
ub = 5*ones(4*N,1);

Aeq = Xf_set_H;
beq = Xf_set_h;

% Define IC_test_vals as the set of initial conditions to consider
r = 1;
s = 1;

res = 10;
bnd_x = 0.5;
bnd_y = 0.5;

mat = zeros(res,res,3);

fprintf('\tdone!\n');

% plot the initial conditions which were steered towards the terminal set
% X_f within N steps

disp('------------------------------------------------------------------');
disp('            INVARIANT CONTROL ADMISSIBLE SET X_f ');
disp('');
disp('------------------------------------------------------------------');
disp('Hx < h defines the set X_f');
disp('See workspace for H and h as Xf_set_H and Xf_set_h respectively');

% PLOT THE CONSTRAINT SET X_f

H_xyz = Xf_set_H(:,[1,2,3]);


figure(3);
plot3(H_xyz(:,1),H_xyz(:,2),H_xyz(:,3),'*m');
grid on;
view(2);

[K,V] = convhull(H_xyz(:,1),H_xyz(:,2));
hold on
plot(H_xyz(K,1),H_xyz(K,2),'r-');

xx = -1:.05:1;
yy = abs(sqrt(xx));
[x,y] = pol2cart(xx,yy);
k = convhull(x,y,x+1);
% figure(9);
% plot(x(k),y(k),'r-',x,y,'b*')
% 
% PLOT OF REPORT
