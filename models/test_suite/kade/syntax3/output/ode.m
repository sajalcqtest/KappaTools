function main=main()
% command line: 
%      'KaDE' 'syntax3.ka' '-syntax' '3' '-d' 'output' '-l' '1' '-p''0.01'
%% THINGS THAT ARE KNOWN FROM KAPPA FILE AND KaSim OPTIONS:
%% 
%% init - the initial abundances of each species and token
%% tinit - the initial simulation time (likely 0)
%% tend - the final simulation time 
%% initialstep - initial time step at the beginning of numerical integration
%% maxstep - maximal time step for numerical integration
%% reltol - relative error tolerance;
%% abstol - absolute error tolerance;
%% period - the time period between points to return
%%
%% variables (init(i),y(i)) denote numbers of embeddings 
%% rule rates are corrected by the number of automorphisms in the lhs of rules


tinit=0;
tend=1;
initialstep=1e-05;
maxstep=0.02;
reltol=0.001;
abstol=0.001;
period=0.01;
nonnegative=false;

global nodevar
nodevar=16;
global max_stoc_coef
max_stoc_coef=0;
nvar=3;
nobs=1;
nrules=9;

global var
var=zeros(nvar,1);
global init
init=sparse(nodevar,1);
stoc=zeros(nrules,max_stoc_coef);
global k
global kd
global kun
global kdun
global stoc

k=zeros(nrules,1);
kd=zeros(nrules,1);
kun=zeros(nrules,1);
kdun=zeros(nrules,1);
global jacvar
jacvar=sparse(nvar,nodevar);
global jack
global jackd
global jackun
global jackund
global jacstoc

jack=zeros(nrules,nodevar);
jackd=zeros(nrules,nodevar);
jackun=zeros(nrules,nodevar);
jackund=zeros(nrules,nodevar);

t = 0.000000;

init(16)=t;
init(1)=20; % E(r!1), R(e~u!1,r!2), R(e~u!3,r!2), E(r!3)
var(2)=init(1)+2*init(6)+init(7); % r1: E() ->  @ |E(r[1]), R(e[1] r[2]), R(r[2] e[3]), E(r[3])|_rate
var(1)=init(2)+init(4)+init(5)+init(15)+init(10)+init(11)+init(9)+init(1)+2*init(6)+init(7); % d

k(1)=1; % E(r), R(e) -> E(r!1), R(e!1)
k(2)=1; % R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
k(3)=1; %  -> E(r)
k(4)=1; %  -> R(e~u,r)
k(5)=1; % R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
k(6)=1; % R(e) -> R(e~u)
k(7)=1; % R(e~p?) -> R(e~u?)

uiIsOctave = false;
uiIsMatlab = false;
LIC = license('inuse');
for elem = 1:numel(LIC)
    envStr = LIC(elem).feature
    if strcmpi(envStr,'octave')
       LICname=envStr;
       uiIsOctave = true;
       break
    end
    if strcmpi(envStr,'matlab')
       LICname=envStr
       uiIsMatlab = true;
       break
    end
end


if nonnegative 
   options = odeset('RelTol', reltol, ...
                    'AbsTol', abstol, ...
                    'InitialStep', initialstep, ...
                    'MaxStep', maxstep, ...
                    'Jacobian', @ode_jacobian, ...
                   'NonNegative', [1:1:15]);
else
   options = odeset('RelTol', reltol, ...
                    'AbsTol', abstol, ...
                    'InitialStep', initialstep, ...
                    'MaxStep', maxstep, ...
                    'Jacobian', @ode_jacobian);
end


if nonnegative
   if uiIsMatlab
      soln =  ode15s(@ode_aux,[tinit tend],ode_init(),options);
      soln.y=soln.y';
      vt = soln.x;
      vy = soln.y;
   elseif uiIsOctave
      [vt,vy] = ode23s(@ode_aux,[tinit tend],ode_init(),options);
   end
else
   if uiIsMatlab
      soln =  ode15s(@ode_aux,[tinit tend],ode_init(),options);
      soln.y=soln.y';
      vt = soln.x;
      vy = soln.y;
   elseif uiIsOctave
      soln = ode2r(@ode_aux,[tinit tend],ode_init(),options);
      vt = soln.x;
      vy = soln.y;
   end
end;


nrows = length(vt);

tmp = zeros(nodevar,1);

n_points = floor ((tend-tinit)/period)+1;
t = linspace(tinit, tend, n_points);
obs = zeros(nrows,nobs);

for j=1:nrows
    for i=1:nodevar
        z(i)=vy(j,i);
    end
    h=ode_obs(z);
    for i=1:nobs
        obs(j,i)=h(i);
    end
end
if nobs==1
   y = interp1(vt, obs, t, 'pchip')';
else
   y = interp1(vt, obs, t, 'pchip');
end


filename = 'data.csv';
fid = fopen (filename,'w');
fprintf(fid,'# KaDE syntax3.ka -syntax 3 -d output -l 1 -p 0.01\n')
fprintf(fid,'# ')
fprintf(fid,'[T],')
fprintf(fid,'\n')
for j=1:n_points
    for i=1:nobs
        fprintf(fid,'%f,',y(j,i));
    end
    fprintf(fid,'\n');
end
fclose(fid);


end



function Init=ode_init()

global nodevar
global init
Init=zeros(nodevar,1);

Init(1) = init(1); % E(r!1), R(e~u!1,r!2), R(e~u!3,r!2), E(r!3)
Init(2) = init(2); % E(r)
Init(3) = init(3); % R(e~u,r)
Init(4) = init(4); % E(r!1), R(e~u!1,r)
Init(5) = init(5); % E(r!1), R(e~p!1,r)
Init(6) = init(6); % E(r!1), R(e~u!1,r!2), R(e~p!3,r!2), E(r!3)
Init(7) = init(7); % E(r!1), R(e~p!1,r!2), R(e~p!3,r!2), E(r!3)
Init(8) = init(8); % R(e~p,r)
Init(9) = init(9); % E(r!1), R(e~p,r!2), R(e~p!1,r!2)
Init(10) = init(10); % E(r!1), R(e~u,r!2), R(e~p!1,r!2)
Init(11) = init(11); % E(r!1), R(e~p,r!2), R(e~u!1,r!2)
Init(12) = init(12); % R(e~p,r!1), R(e~p,r!1)
Init(13) = init(13); % R(e~u,r!1), R(e~p,r!1)
Init(14) = init(14); % R(e~u,r!1), R(e~u,r!1)
Init(15) = init(15); % E(r!1), R(e~u!1,r!2), R(e~u,r!2)
Init(16) = init(16); % t
end


function dydt=ode_aux(t,y)

global nodevar
global max_stoc_coef
global var
global k
global kd
global kun
global kdun
global stoc

var(2)=y(1)+2*y(6)+y(7); % r1: E() ->  @ |E(r[1]), R(e[1] r[2]), R(r[2] e[3]), E(r[3])|_rate
var(1)=y(2)+y(4)+y(5)+y(15)+y(10)+y(11)+y(9)+y(1)+2*y(6)+y(7); % d

k(8)=var(2);
k(9)=var(1);

dydt=zeros(nodevar,1);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(1)=dydt(1)-2*k(8)*y(1)/2;
dydt(15)=dydt(15)+k(8)*y(1)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(1)=dydt(1)-2*k(8)*y(1)/2;
dydt(15)=dydt(15)+k(8)*y(1)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r) + E(r)

dydt(1)=dydt(1)-2*k(9)*y(1)/2;
dydt(2)=dydt(2)+k(9)*y(1)/2;
dydt(4)=dydt(4)+k(9)*y(1)/2;

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(1)=dydt(1)-2*k(2)*y(1)/2;
dydt(6)=dydt(6)+k(2)*y(1)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r) + E(r)

dydt(1)=dydt(1)-2*k(9)*y(1)/2;
dydt(2)=dydt(2)+k(9)*y(1)/2;
dydt(4)=dydt(4)+k(9)*y(1)/2;

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(1)=dydt(1)-2*k(2)*y(1)/2;
dydt(6)=dydt(6)+k(2)*y(1)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p,r!2).R(e~u!1,r!2)

dydt(6)=dydt(6)-k(8)*y(6);
dydt(11)=dydt(11)+k(8)*y(6);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

dydt(6)=dydt(6)-k(8)*y(6);
dydt(10)=dydt(10)+k(8)*y(6);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r) + E(r)

dydt(6)=dydt(6)-k(9)*y(6);
dydt(2)=dydt(2)+k(9)*y(6);
dydt(4)=dydt(4)+k(9)*y(6);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3)

dydt(6)=dydt(6)-k(7)*y(6);
dydt(1)=dydt(1)+2*k(7)*y(6);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r) + E(r)

dydt(6)=dydt(6)-k(9)*y(6);
dydt(2)=dydt(2)+k(9)*y(6);
dydt(5)=dydt(5)+k(9)*y(6);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(6)=dydt(6)-k(2)*y(6);
dydt(7)=dydt(7)+2*k(2)*y(6);

% rule    : E() -> 
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> R(e~u,r!1).R(e~p,r!1)

dydt(10)=dydt(10)-k(8)*y(10);
dydt(13)=dydt(13)+k(8)*y(10);

% rule    : R() -> 
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> R(e~u,r) + E(r)

dydt(10)=dydt(10)-k(9)*y(10);
dydt(2)=dydt(2)+k(9)*y(10);
dydt(3)=dydt(3)+k(9)*y(10);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(10)=dydt(10)-k(7)*y(10);
dydt(15)=dydt(15)+k(7)*y(10);

% rule    : R() -> 
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> E(r!1).R(e~p!1,r)

dydt(10)=dydt(10)-k(9)*y(10);
dydt(5)=dydt(5)+k(9)*y(10);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

dydt(10)=dydt(10)-k(6)*y(10);
dydt(10)=dydt(10)+k(6)*y(10);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(2)=dydt(2)-k(1)*y(2)*y(10);
dydt(10)=dydt(10)-k(1)*y(2)*y(10);
dydt(6)=dydt(6)+k(1)*y(2)*y(10);

% rule    : E() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> R(e~u,r!1).R(e~p,r!1)

dydt(11)=dydt(11)-k(8)*y(11);
dydt(13)=dydt(13)+k(8)*y(11);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> R(e~p,r) + E(r)

dydt(11)=dydt(11)-k(9)*y(11);
dydt(2)=dydt(2)+k(9)*y(11);
dydt(8)=dydt(8)+k(9)*y(11);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

dydt(11)=dydt(11)-k(2)*y(11);
dydt(9)=dydt(9)+k(2)*y(11);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~u!1,r)

dydt(11)=dydt(11)-k(9)*y(11);
dydt(4)=dydt(4)+k(9)*y(11);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(11)=dydt(11)-k(7)*y(11);
dydt(15)=dydt(15)+k(7)*y(11);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(11)=dydt(11)-k(6)*y(11);
dydt(15)=dydt(15)+k(6)*y(11);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(2)=dydt(2)-k(1)*y(2)*y(11);
dydt(11)=dydt(11)-k(1)*y(2)*y(11);
dydt(6)=dydt(6)+k(1)*y(2)*y(11);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> R(e~u,r!1).R(e~u,r!1)

dydt(15)=dydt(15)-k(8)*y(15);
dydt(14)=dydt(14)+2*k(8)*y(15);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> E(r!1).R(e~u!1,r)

dydt(15)=dydt(15)-k(9)*y(15);
dydt(4)=dydt(4)+k(9)*y(15);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(15)=dydt(15)-k(6)*y(15);
dydt(15)=dydt(15)+k(6)*y(15);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3)

dydt(2)=dydt(2)-k(1)*y(2)*y(15);
dydt(15)=dydt(15)-k(1)*y(2)*y(15);
dydt(1)=dydt(1)+2*k(1)*y(2)*y(15);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> R(e~u,r) + E(r)

dydt(15)=dydt(15)-k(9)*y(15);
dydt(2)=dydt(2)+k(9)*y(15);
dydt(3)=dydt(3)+k(9)*y(15);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

dydt(15)=dydt(15)-k(2)*y(15);
dydt(10)=dydt(10)+k(2)*y(15);

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r)

dydt(14)=dydt(14)-2*k(9)*y(14)/2;
dydt(3)=dydt(3)+k(9)*y(14)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r!1).R(e~u,r!1)

dydt(14)=dydt(14)-2*k(6)*y(14)/2;
dydt(14)=dydt(14)+2*k(6)*y(14)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~u,r!1) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(2)=dydt(2)-k(1)*y(2)*y(14)/2;
dydt(14)=dydt(14)-2*k(1)*y(2)*y(14)/2;
dydt(15)=dydt(15)+k(1)*y(2)*y(14)/2;

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r)

dydt(14)=dydt(14)-2*k(9)*y(14)/2;
dydt(3)=dydt(3)+k(9)*y(14)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r!1).R(e~u,r!1)

dydt(14)=dydt(14)-2*k(6)*y(14)/2;
dydt(14)=dydt(14)+2*k(6)*y(14)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~u,r!1) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

dydt(2)=dydt(2)-k(1)*y(2)*y(14)/2;
dydt(14)=dydt(14)-2*k(1)*y(2)*y(14)/2;
dydt(15)=dydt(15)+k(1)*y(2)*y(14)/2;

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r)

dydt(13)=dydt(13)-k(9)*y(13);
dydt(3)=dydt(3)+k(9)*y(13);

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~u,r!1)

dydt(13)=dydt(13)-k(7)*y(13);
dydt(14)=dydt(14)+2*k(7)*y(13);

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~u,r!1)

dydt(13)=dydt(13)-k(6)*y(13);
dydt(14)=dydt(14)+2*k(6)*y(13);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

dydt(2)=dydt(2)-k(1)*y(2)*y(13);
dydt(13)=dydt(13)-k(1)*y(2)*y(13);
dydt(10)=dydt(10)+k(1)*y(2)*y(13);

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~p,r)

dydt(13)=dydt(13)-k(9)*y(13);
dydt(8)=dydt(8)+k(9)*y(13);

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

dydt(13)=dydt(13)-k(6)*y(13);
dydt(13)=dydt(13)+k(6)*y(13);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~p,r!2).R(e~u!1,r!2)

dydt(2)=dydt(2)-k(1)*y(2)*y(13);
dydt(13)=dydt(13)-k(1)*y(2)*y(13);
dydt(11)=dydt(11)+k(1)*y(2)*y(13);

% rule    : R() -> 
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~p,r)

dydt(12)=dydt(12)-2*k(9)*y(12)/2;
dydt(8)=dydt(8)+k(9)*y(12)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

dydt(12)=dydt(12)-2*k(7)*y(12)/2;
dydt(13)=dydt(13)+k(7)*y(12)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

dydt(12)=dydt(12)-2*k(6)*y(12)/2;
dydt(13)=dydt(13)+k(6)*y(12)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~p,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

dydt(2)=dydt(2)-k(1)*y(2)*y(12)/2;
dydt(12)=dydt(12)-2*k(1)*y(2)*y(12)/2;
dydt(9)=dydt(9)+k(1)*y(2)*y(12)/2;

% rule    : R() -> 
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~p,r)

dydt(12)=dydt(12)-2*k(9)*y(12)/2;
dydt(8)=dydt(8)+k(9)*y(12)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

dydt(12)=dydt(12)-2*k(7)*y(12)/2;
dydt(13)=dydt(13)+k(7)*y(12)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

dydt(12)=dydt(12)-2*k(6)*y(12)/2;
dydt(13)=dydt(13)+k(6)*y(12)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~p,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

dydt(2)=dydt(2)-k(1)*y(2)*y(12)/2;
dydt(12)=dydt(12)-2*k(1)*y(2)*y(12)/2;
dydt(9)=dydt(9)+k(1)*y(2)*y(12)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> R(e~p,r!1).R(e~p,r!1)

dydt(9)=dydt(9)-k(8)*y(9);
dydt(12)=dydt(12)+2*k(8)*y(9);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> R(e~p,r) + E(r)

dydt(9)=dydt(9)-k(9)*y(9);
dydt(2)=dydt(2)+k(9)*y(9);
dydt(8)=dydt(8)+k(9)*y(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~p,r!2).R(e~u!1,r!2)

dydt(9)=dydt(9)-k(7)*y(9);
dydt(11)=dydt(11)+k(7)*y(9);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~p!1,r)

dydt(9)=dydt(9)-k(9)*y(9);
dydt(5)=dydt(5)+k(9)*y(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

dydt(9)=dydt(9)-k(7)*y(9);
dydt(10)=dydt(10)+k(7)*y(9);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

dydt(9)=dydt(9)-k(6)*y(9);
dydt(10)=dydt(10)+k(6)*y(9);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) + E(r) -> E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(2)=dydt(2)-k(1)*y(2)*y(9);
dydt(9)=dydt(9)-k(1)*y(2)*y(9);
dydt(7)=dydt(7)+2*k(1)*y(2)*y(9);

% rule    : E() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

dydt(7)=dydt(7)-2*k(8)*y(7)/2;
dydt(9)=dydt(9)+k(8)*y(7)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

dydt(7)=dydt(7)-2*k(8)*y(7)/2;
dydt(9)=dydt(9)+k(8)*y(7)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r) + E(r)

dydt(7)=dydt(7)-2*k(9)*y(7)/2;
dydt(2)=dydt(2)+k(9)*y(7)/2;
dydt(5)=dydt(5)+k(9)*y(7)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(7)=dydt(7)-2*k(7)*y(7)/2;
dydt(6)=dydt(6)+k(7)*y(7)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r) + E(r)

dydt(7)=dydt(7)-2*k(9)*y(7)/2;
dydt(2)=dydt(2)+k(9)*y(7)/2;
dydt(5)=dydt(5)+k(9)*y(7)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(7)=dydt(7)-2*k(7)*y(7)/2;
dydt(6)=dydt(6)+k(7)*y(7)/2;

% rule    : R() -> 
% reaction: R(e~p,r) -> 

dydt(8)=dydt(8)-k(9)*y(8);

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~p,r) -> R(e~u,r)

dydt(8)=dydt(8)-k(7)*y(8);
dydt(3)=dydt(3)+k(7)*y(8);

% rule    : R(e) -> R(e~u)
% reaction: R(e~p,r) -> R(e~u,r)

dydt(8)=dydt(8)-k(6)*y(8);
dydt(3)=dydt(3)+k(6)*y(8);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~p,r) + E(r) -> E(r!1).R(e~p!1,r)

dydt(2)=dydt(2)-k(1)*y(2)*y(8);
dydt(8)=dydt(8)-k(1)*y(2)*y(8);
dydt(5)=dydt(5)+k(1)*y(2)*y(8);

% rule    : E() -> 
% reaction: E(r!1).R(e~p!1,r) -> R(e~p,r)

dydt(5)=dydt(5)-k(8)*y(5);
dydt(8)=dydt(8)+k(8)*y(5);

% rule    : R() -> 
% reaction: E(r!1).R(e~p!1,r) -> E(r)

dydt(5)=dydt(5)-k(9)*y(5);
dydt(2)=dydt(2)+k(9)*y(5);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p!1,r) -> E(r!1).R(e~u!1,r)

dydt(5)=dydt(5)-k(7)*y(5);
dydt(4)=dydt(4)+k(7)*y(5);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~p!1,r) + E(r!1).R(e~p!1,r) -> E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(5)=dydt(5)-k(5)*y(5)*y(5);
dydt(5)=dydt(5)-k(5)*y(5)*y(5);
dydt(7)=dydt(7)+2*k(5)*y(5)*y(5);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~p!1,r) + E(r!1).R(e~u!1,r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(4)=dydt(4)-k(5)*y(4)*y(5);
dydt(5)=dydt(5)-k(5)*y(4)*y(5);
dydt(6)=dydt(6)+k(5)*y(4)*y(5);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~u!1,r) + E(r!1).R(e~p!1,r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

dydt(5)=dydt(5)-k(5)*y(5)*y(4);
dydt(4)=dydt(4)-k(5)*y(5)*y(4);
dydt(6)=dydt(6)+k(5)*y(5)*y(4);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r) -> R(e~u,r)

dydt(4)=dydt(4)-k(8)*y(4);
dydt(3)=dydt(3)+k(8)*y(4);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r) -> E(r)

dydt(4)=dydt(4)-k(9)*y(4);
dydt(2)=dydt(2)+k(9)*y(4);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r) -> E(r!1).R(e~p!1,r)

dydt(4)=dydt(4)-k(2)*y(4);
dydt(5)=dydt(5)+k(2)*y(4);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~u!1,r) + E(r!1).R(e~u!1,r) -> E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3)

dydt(4)=dydt(4)-k(5)*y(4)*y(4);
dydt(4)=dydt(4)-k(5)*y(4)*y(4);
dydt(1)=dydt(1)+2*k(5)*y(4)*y(4);

% rule    : E() -> 
% reaction: E(r) -> 

dydt(2)=dydt(2)-k(8)*y(2);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r) + E(r) -> E(r!1).R(e~u!1,r)

dydt(2)=dydt(2)-k(1)*y(2)*y(3);
dydt(3)=dydt(3)-k(1)*y(2)*y(3);
dydt(4)=dydt(4)+k(1)*y(2)*y(3);

% rule    : R() -> 
% reaction: R(e~u,r) -> 

dydt(3)=dydt(3)-k(9)*y(3);

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r) -> R(e~u,r)

dydt(3)=dydt(3)-k(6)*y(3);
dydt(3)=dydt(3)+k(6)*y(3);

% rule    :  -> R(e~u,r)
% reaction:  -> R(e~u,r)

dydt(3)=dydt(3)+k(4);

% rule    :  -> E(r)
% reaction:  -> E(r)

dydt(2)=dydt(2)+k(3);
dydt(16)=1;

end


function jac=ode_jacobian(t,y)

global nodevar
global max_stoc_coef
global jacvar
global var
global k
global kd
global kun
global kdun
global stoc

global jack
global jackd
global jackun
global jackund
global jacstoc

var(2)=y(1)+2*y(6)+y(7); % r1: E() ->  @ |E(r[1]), R(e[1] r[2]), R(r[2] e[3]), E(r[3])|_rate
var(1)=y(2)+y(4)+y(5)+y(15)+y(10)+y(11)+y(9)+y(1)+2*y(6)+y(7); % d

k(8)=var(2);
k(9)=var(1);
jacvar(2,1)=2;
jacvar(2,6)=2;
jacvar(2,7)=2;
jacvar(1,1)=2;
jacvar(1,2)=1;
jacvar(1,4)=1;
jacvar(1,5)=1;
jacvar(1,6)=2;
jacvar(1,7)=2;
jacvar(1,9)=1;
jacvar(1,10)=1;
jacvar(1,11)=1;
jacvar(1,15)=1;

jack(8,1)=jacvar(2,1);
jack(8,6)=jacvar(2,6);
jack(8,7)=jacvar(2,7);
jack(9,1)=jacvar(1,1);
jack(9,2)=jacvar(1,2);
jack(9,4)=jacvar(1,4);
jack(9,5)=jacvar(1,5);
jack(9,6)=jacvar(1,6);
jack(9,7)=jacvar(1,7);
jack(9,9)=jacvar(1,9);
jack(9,10)=jacvar(1,10);
jack(9,11)=jacvar(1,11);
jack(9,15)=jacvar(1,15);

jac=sparse(nodevar,nodevar);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(1,1)=jac(1,1)-2*jack(8,1)*y(1)/2;
jac(1,6)=jac(1,6)-2*jack(8,6)*y(1)/2;
jac(1,7)=jac(1,7)-2*jack(8,7)*y(1)/2;
jac(1,1)=jac(1,1)-2*k(8)/2;
jac(15,1)=jac(15,1)+jack(8,1)*y(1)/2;
jac(15,6)=jac(15,6)+jack(8,6)*y(1)/2;
jac(15,7)=jac(15,7)+jack(8,7)*y(1)/2;
jac(15,1)=jac(15,1)+k(8)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(1,1)=jac(1,1)-2*jack(8,1)*y(1)/2;
jac(1,6)=jac(1,6)-2*jack(8,6)*y(1)/2;
jac(1,7)=jac(1,7)-2*jack(8,7)*y(1)/2;
jac(1,1)=jac(1,1)-2*k(8)/2;
jac(15,1)=jac(15,1)+jack(8,1)*y(1)/2;
jac(15,6)=jac(15,6)+jack(8,6)*y(1)/2;
jac(15,7)=jac(15,7)+jack(8,7)*y(1)/2;
jac(15,1)=jac(15,1)+k(8)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r) + E(r)

jac(1,1)=jac(1,1)-2*jack(9,1)*y(1)/2;
jac(1,2)=jac(1,2)-2*jack(9,2)*y(1)/2;
jac(1,4)=jac(1,4)-2*jack(9,4)*y(1)/2;
jac(1,5)=jac(1,5)-2*jack(9,5)*y(1)/2;
jac(1,6)=jac(1,6)-2*jack(9,6)*y(1)/2;
jac(1,7)=jac(1,7)-2*jack(9,7)*y(1)/2;
jac(1,9)=jac(1,9)-2*jack(9,9)*y(1)/2;
jac(1,10)=jac(1,10)-2*jack(9,10)*y(1)/2;
jac(1,11)=jac(1,11)-2*jack(9,11)*y(1)/2;
jac(1,15)=jac(1,15)-2*jack(9,15)*y(1)/2;
jac(1,1)=jac(1,1)-2*k(9)/2;
jac(2,1)=jac(2,1)+jack(9,1)*y(1)/2;
jac(2,2)=jac(2,2)+jack(9,2)*y(1)/2;
jac(2,4)=jac(2,4)+jack(9,4)*y(1)/2;
jac(2,5)=jac(2,5)+jack(9,5)*y(1)/2;
jac(2,6)=jac(2,6)+jack(9,6)*y(1)/2;
jac(2,7)=jac(2,7)+jack(9,7)*y(1)/2;
jac(2,9)=jac(2,9)+jack(9,9)*y(1)/2;
jac(2,10)=jac(2,10)+jack(9,10)*y(1)/2;
jac(2,11)=jac(2,11)+jack(9,11)*y(1)/2;
jac(2,15)=jac(2,15)+jack(9,15)*y(1)/2;
jac(2,1)=jac(2,1)+k(9)/2;
jac(4,1)=jac(4,1)+jack(9,1)*y(1)/2;
jac(4,2)=jac(4,2)+jack(9,2)*y(1)/2;
jac(4,4)=jac(4,4)+jack(9,4)*y(1)/2;
jac(4,5)=jac(4,5)+jack(9,5)*y(1)/2;
jac(4,6)=jac(4,6)+jack(9,6)*y(1)/2;
jac(4,7)=jac(4,7)+jack(9,7)*y(1)/2;
jac(4,9)=jac(4,9)+jack(9,9)*y(1)/2;
jac(4,10)=jac(4,10)+jack(9,10)*y(1)/2;
jac(4,11)=jac(4,11)+jack(9,11)*y(1)/2;
jac(4,15)=jac(4,15)+jack(9,15)*y(1)/2;
jac(4,1)=jac(4,1)+k(9)/2;

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(1,1)=jac(1,1)-2*k(2)/2;
jac(6,1)=jac(6,1)+k(2)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r) + E(r)

jac(1,1)=jac(1,1)-2*jack(9,1)*y(1)/2;
jac(1,2)=jac(1,2)-2*jack(9,2)*y(1)/2;
jac(1,4)=jac(1,4)-2*jack(9,4)*y(1)/2;
jac(1,5)=jac(1,5)-2*jack(9,5)*y(1)/2;
jac(1,6)=jac(1,6)-2*jack(9,6)*y(1)/2;
jac(1,7)=jac(1,7)-2*jack(9,7)*y(1)/2;
jac(1,9)=jac(1,9)-2*jack(9,9)*y(1)/2;
jac(1,10)=jac(1,10)-2*jack(9,10)*y(1)/2;
jac(1,11)=jac(1,11)-2*jack(9,11)*y(1)/2;
jac(1,15)=jac(1,15)-2*jack(9,15)*y(1)/2;
jac(1,1)=jac(1,1)-2*k(9)/2;
jac(2,1)=jac(2,1)+jack(9,1)*y(1)/2;
jac(2,2)=jac(2,2)+jack(9,2)*y(1)/2;
jac(2,4)=jac(2,4)+jack(9,4)*y(1)/2;
jac(2,5)=jac(2,5)+jack(9,5)*y(1)/2;
jac(2,6)=jac(2,6)+jack(9,6)*y(1)/2;
jac(2,7)=jac(2,7)+jack(9,7)*y(1)/2;
jac(2,9)=jac(2,9)+jack(9,9)*y(1)/2;
jac(2,10)=jac(2,10)+jack(9,10)*y(1)/2;
jac(2,11)=jac(2,11)+jack(9,11)*y(1)/2;
jac(2,15)=jac(2,15)+jack(9,15)*y(1)/2;
jac(2,1)=jac(2,1)+k(9)/2;
jac(4,1)=jac(4,1)+jack(9,1)*y(1)/2;
jac(4,2)=jac(4,2)+jack(9,2)*y(1)/2;
jac(4,4)=jac(4,4)+jack(9,4)*y(1)/2;
jac(4,5)=jac(4,5)+jack(9,5)*y(1)/2;
jac(4,6)=jac(4,6)+jack(9,6)*y(1)/2;
jac(4,7)=jac(4,7)+jack(9,7)*y(1)/2;
jac(4,9)=jac(4,9)+jack(9,9)*y(1)/2;
jac(4,10)=jac(4,10)+jack(9,10)*y(1)/2;
jac(4,11)=jac(4,11)+jack(9,11)*y(1)/2;
jac(4,15)=jac(4,15)+jack(9,15)*y(1)/2;
jac(4,1)=jac(4,1)+k(9)/2;

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(1,1)=jac(1,1)-2*k(2)/2;
jac(6,1)=jac(6,1)+k(2)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p,r!2).R(e~u!1,r!2)

jac(6,1)=jac(6,1)-jack(8,1)*y(6);
jac(6,6)=jac(6,6)-jack(8,6)*y(6);
jac(6,7)=jac(6,7)-jack(8,7)*y(6);
jac(6,6)=jac(6,6)-k(8);
jac(11,1)=jac(11,1)+jack(8,1)*y(6);
jac(11,6)=jac(11,6)+jack(8,6)*y(6);
jac(11,7)=jac(11,7)+jack(8,7)*y(6);
jac(11,6)=jac(11,6)+k(8);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

jac(6,1)=jac(6,1)-jack(8,1)*y(6);
jac(6,6)=jac(6,6)-jack(8,6)*y(6);
jac(6,7)=jac(6,7)-jack(8,7)*y(6);
jac(6,6)=jac(6,6)-k(8);
jac(10,1)=jac(10,1)+jack(8,1)*y(6);
jac(10,6)=jac(10,6)+jack(8,6)*y(6);
jac(10,7)=jac(10,7)+jack(8,7)*y(6);
jac(10,6)=jac(10,6)+k(8);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r) + E(r)

jac(6,1)=jac(6,1)-jack(9,1)*y(6);
jac(6,2)=jac(6,2)-jack(9,2)*y(6);
jac(6,4)=jac(6,4)-jack(9,4)*y(6);
jac(6,5)=jac(6,5)-jack(9,5)*y(6);
jac(6,6)=jac(6,6)-jack(9,6)*y(6);
jac(6,7)=jac(6,7)-jack(9,7)*y(6);
jac(6,9)=jac(6,9)-jack(9,9)*y(6);
jac(6,10)=jac(6,10)-jack(9,10)*y(6);
jac(6,11)=jac(6,11)-jack(9,11)*y(6);
jac(6,15)=jac(6,15)-jack(9,15)*y(6);
jac(6,6)=jac(6,6)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(6);
jac(2,2)=jac(2,2)+jack(9,2)*y(6);
jac(2,4)=jac(2,4)+jack(9,4)*y(6);
jac(2,5)=jac(2,5)+jack(9,5)*y(6);
jac(2,6)=jac(2,6)+jack(9,6)*y(6);
jac(2,7)=jac(2,7)+jack(9,7)*y(6);
jac(2,9)=jac(2,9)+jack(9,9)*y(6);
jac(2,10)=jac(2,10)+jack(9,10)*y(6);
jac(2,11)=jac(2,11)+jack(9,11)*y(6);
jac(2,15)=jac(2,15)+jack(9,15)*y(6);
jac(2,6)=jac(2,6)+k(9);
jac(4,1)=jac(4,1)+jack(9,1)*y(6);
jac(4,2)=jac(4,2)+jack(9,2)*y(6);
jac(4,4)=jac(4,4)+jack(9,4)*y(6);
jac(4,5)=jac(4,5)+jack(9,5)*y(6);
jac(4,6)=jac(4,6)+jack(9,6)*y(6);
jac(4,7)=jac(4,7)+jack(9,7)*y(6);
jac(4,9)=jac(4,9)+jack(9,9)*y(6);
jac(4,10)=jac(4,10)+jack(9,10)*y(6);
jac(4,11)=jac(4,11)+jack(9,11)*y(6);
jac(4,15)=jac(4,15)+jack(9,15)*y(6);
jac(4,6)=jac(4,6)+k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3)

jac(6,6)=jac(6,6)-k(7);
jac(1,6)=jac(1,6)+2*k(7);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r) + E(r)

jac(6,1)=jac(6,1)-jack(9,1)*y(6);
jac(6,2)=jac(6,2)-jack(9,2)*y(6);
jac(6,4)=jac(6,4)-jack(9,4)*y(6);
jac(6,5)=jac(6,5)-jack(9,5)*y(6);
jac(6,6)=jac(6,6)-jack(9,6)*y(6);
jac(6,7)=jac(6,7)-jack(9,7)*y(6);
jac(6,9)=jac(6,9)-jack(9,9)*y(6);
jac(6,10)=jac(6,10)-jack(9,10)*y(6);
jac(6,11)=jac(6,11)-jack(9,11)*y(6);
jac(6,15)=jac(6,15)-jack(9,15)*y(6);
jac(6,6)=jac(6,6)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(6);
jac(2,2)=jac(2,2)+jack(9,2)*y(6);
jac(2,4)=jac(2,4)+jack(9,4)*y(6);
jac(2,5)=jac(2,5)+jack(9,5)*y(6);
jac(2,6)=jac(2,6)+jack(9,6)*y(6);
jac(2,7)=jac(2,7)+jack(9,7)*y(6);
jac(2,9)=jac(2,9)+jack(9,9)*y(6);
jac(2,10)=jac(2,10)+jack(9,10)*y(6);
jac(2,11)=jac(2,11)+jack(9,11)*y(6);
jac(2,15)=jac(2,15)+jack(9,15)*y(6);
jac(2,6)=jac(2,6)+k(9);
jac(5,1)=jac(5,1)+jack(9,1)*y(6);
jac(5,2)=jac(5,2)+jack(9,2)*y(6);
jac(5,4)=jac(5,4)+jack(9,4)*y(6);
jac(5,5)=jac(5,5)+jack(9,5)*y(6);
jac(5,6)=jac(5,6)+jack(9,6)*y(6);
jac(5,7)=jac(5,7)+jack(9,7)*y(6);
jac(5,9)=jac(5,9)+jack(9,9)*y(6);
jac(5,10)=jac(5,10)+jack(9,10)*y(6);
jac(5,11)=jac(5,11)+jack(9,11)*y(6);
jac(5,15)=jac(5,15)+jack(9,15)*y(6);
jac(5,6)=jac(5,6)+k(9);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3)

jac(6,6)=jac(6,6)-k(2);
jac(7,6)=jac(7,6)+2*k(2);

% rule    : E() -> 
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> R(e~u,r!1).R(e~p,r!1)

jac(10,1)=jac(10,1)-jack(8,1)*y(10);
jac(10,6)=jac(10,6)-jack(8,6)*y(10);
jac(10,7)=jac(10,7)-jack(8,7)*y(10);
jac(10,10)=jac(10,10)-k(8);
jac(13,1)=jac(13,1)+jack(8,1)*y(10);
jac(13,6)=jac(13,6)+jack(8,6)*y(10);
jac(13,7)=jac(13,7)+jack(8,7)*y(10);
jac(13,10)=jac(13,10)+k(8);

% rule    : R() -> 
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> R(e~u,r) + E(r)

jac(10,1)=jac(10,1)-jack(9,1)*y(10);
jac(10,2)=jac(10,2)-jack(9,2)*y(10);
jac(10,4)=jac(10,4)-jack(9,4)*y(10);
jac(10,5)=jac(10,5)-jack(9,5)*y(10);
jac(10,6)=jac(10,6)-jack(9,6)*y(10);
jac(10,7)=jac(10,7)-jack(9,7)*y(10);
jac(10,9)=jac(10,9)-jack(9,9)*y(10);
jac(10,10)=jac(10,10)-jack(9,10)*y(10);
jac(10,11)=jac(10,11)-jack(9,11)*y(10);
jac(10,15)=jac(10,15)-jack(9,15)*y(10);
jac(10,10)=jac(10,10)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(10);
jac(2,2)=jac(2,2)+jack(9,2)*y(10);
jac(2,4)=jac(2,4)+jack(9,4)*y(10);
jac(2,5)=jac(2,5)+jack(9,5)*y(10);
jac(2,6)=jac(2,6)+jack(9,6)*y(10);
jac(2,7)=jac(2,7)+jack(9,7)*y(10);
jac(2,9)=jac(2,9)+jack(9,9)*y(10);
jac(2,10)=jac(2,10)+jack(9,10)*y(10);
jac(2,11)=jac(2,11)+jack(9,11)*y(10);
jac(2,15)=jac(2,15)+jack(9,15)*y(10);
jac(2,10)=jac(2,10)+k(9);
jac(3,1)=jac(3,1)+jack(9,1)*y(10);
jac(3,2)=jac(3,2)+jack(9,2)*y(10);
jac(3,4)=jac(3,4)+jack(9,4)*y(10);
jac(3,5)=jac(3,5)+jack(9,5)*y(10);
jac(3,6)=jac(3,6)+jack(9,6)*y(10);
jac(3,7)=jac(3,7)+jack(9,7)*y(10);
jac(3,9)=jac(3,9)+jack(9,9)*y(10);
jac(3,10)=jac(3,10)+jack(9,10)*y(10);
jac(3,11)=jac(3,11)+jack(9,11)*y(10);
jac(3,15)=jac(3,15)+jack(9,15)*y(10);
jac(3,10)=jac(3,10)+k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(10,10)=jac(10,10)-k(7);
jac(15,10)=jac(15,10)+k(7);

% rule    : R() -> 
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> E(r!1).R(e~p!1,r)

jac(10,1)=jac(10,1)-jack(9,1)*y(10);
jac(10,2)=jac(10,2)-jack(9,2)*y(10);
jac(10,4)=jac(10,4)-jack(9,4)*y(10);
jac(10,5)=jac(10,5)-jack(9,5)*y(10);
jac(10,6)=jac(10,6)-jack(9,6)*y(10);
jac(10,7)=jac(10,7)-jack(9,7)*y(10);
jac(10,9)=jac(10,9)-jack(9,9)*y(10);
jac(10,10)=jac(10,10)-jack(9,10)*y(10);
jac(10,11)=jac(10,11)-jack(9,11)*y(10);
jac(10,15)=jac(10,15)-jack(9,15)*y(10);
jac(10,10)=jac(10,10)-k(9);
jac(5,1)=jac(5,1)+jack(9,1)*y(10);
jac(5,2)=jac(5,2)+jack(9,2)*y(10);
jac(5,4)=jac(5,4)+jack(9,4)*y(10);
jac(5,5)=jac(5,5)+jack(9,5)*y(10);
jac(5,6)=jac(5,6)+jack(9,6)*y(10);
jac(5,7)=jac(5,7)+jack(9,7)*y(10);
jac(5,9)=jac(5,9)+jack(9,9)*y(10);
jac(5,10)=jac(5,10)+jack(9,10)*y(10);
jac(5,11)=jac(5,11)+jack(9,11)*y(10);
jac(5,15)=jac(5,15)+jack(9,15)*y(10);
jac(5,10)=jac(5,10)+k(9);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

jac(10,10)=jac(10,10)-k(6);
jac(10,10)=jac(10,10)+k(6);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~u,r!2).R(e~p!1,r!2) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(2,2)=jac(2,2)-k(1)*y(10);
jac(2,10)=jac(2,10)-k(1)*y(2);
jac(10,2)=jac(10,2)-k(1)*y(10);
jac(10,10)=jac(10,10)-k(1)*y(2);
jac(6,2)=jac(6,2)+k(1)*y(10);
jac(6,10)=jac(6,10)+k(1)*y(2);

% rule    : E() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> R(e~u,r!1).R(e~p,r!1)

jac(11,1)=jac(11,1)-jack(8,1)*y(11);
jac(11,6)=jac(11,6)-jack(8,6)*y(11);
jac(11,7)=jac(11,7)-jack(8,7)*y(11);
jac(11,11)=jac(11,11)-k(8);
jac(13,1)=jac(13,1)+jack(8,1)*y(11);
jac(13,6)=jac(13,6)+jack(8,6)*y(11);
jac(13,7)=jac(13,7)+jack(8,7)*y(11);
jac(13,11)=jac(13,11)+k(8);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> R(e~p,r) + E(r)

jac(11,1)=jac(11,1)-jack(9,1)*y(11);
jac(11,2)=jac(11,2)-jack(9,2)*y(11);
jac(11,4)=jac(11,4)-jack(9,4)*y(11);
jac(11,5)=jac(11,5)-jack(9,5)*y(11);
jac(11,6)=jac(11,6)-jack(9,6)*y(11);
jac(11,7)=jac(11,7)-jack(9,7)*y(11);
jac(11,9)=jac(11,9)-jack(9,9)*y(11);
jac(11,10)=jac(11,10)-jack(9,10)*y(11);
jac(11,11)=jac(11,11)-jack(9,11)*y(11);
jac(11,15)=jac(11,15)-jack(9,15)*y(11);
jac(11,11)=jac(11,11)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(11);
jac(2,2)=jac(2,2)+jack(9,2)*y(11);
jac(2,4)=jac(2,4)+jack(9,4)*y(11);
jac(2,5)=jac(2,5)+jack(9,5)*y(11);
jac(2,6)=jac(2,6)+jack(9,6)*y(11);
jac(2,7)=jac(2,7)+jack(9,7)*y(11);
jac(2,9)=jac(2,9)+jack(9,9)*y(11);
jac(2,10)=jac(2,10)+jack(9,10)*y(11);
jac(2,11)=jac(2,11)+jack(9,11)*y(11);
jac(2,15)=jac(2,15)+jack(9,15)*y(11);
jac(2,11)=jac(2,11)+k(9);
jac(8,1)=jac(8,1)+jack(9,1)*y(11);
jac(8,2)=jac(8,2)+jack(9,2)*y(11);
jac(8,4)=jac(8,4)+jack(9,4)*y(11);
jac(8,5)=jac(8,5)+jack(9,5)*y(11);
jac(8,6)=jac(8,6)+jack(9,6)*y(11);
jac(8,7)=jac(8,7)+jack(9,7)*y(11);
jac(8,9)=jac(8,9)+jack(9,9)*y(11);
jac(8,10)=jac(8,10)+jack(9,10)*y(11);
jac(8,11)=jac(8,11)+jack(9,11)*y(11);
jac(8,15)=jac(8,15)+jack(9,15)*y(11);
jac(8,11)=jac(8,11)+k(9);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

jac(11,11)=jac(11,11)-k(2);
jac(9,11)=jac(9,11)+k(2);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~u!1,r)

jac(11,1)=jac(11,1)-jack(9,1)*y(11);
jac(11,2)=jac(11,2)-jack(9,2)*y(11);
jac(11,4)=jac(11,4)-jack(9,4)*y(11);
jac(11,5)=jac(11,5)-jack(9,5)*y(11);
jac(11,6)=jac(11,6)-jack(9,6)*y(11);
jac(11,7)=jac(11,7)-jack(9,7)*y(11);
jac(11,9)=jac(11,9)-jack(9,9)*y(11);
jac(11,10)=jac(11,10)-jack(9,10)*y(11);
jac(11,11)=jac(11,11)-jack(9,11)*y(11);
jac(11,15)=jac(11,15)-jack(9,15)*y(11);
jac(11,11)=jac(11,11)-k(9);
jac(4,1)=jac(4,1)+jack(9,1)*y(11);
jac(4,2)=jac(4,2)+jack(9,2)*y(11);
jac(4,4)=jac(4,4)+jack(9,4)*y(11);
jac(4,5)=jac(4,5)+jack(9,5)*y(11);
jac(4,6)=jac(4,6)+jack(9,6)*y(11);
jac(4,7)=jac(4,7)+jack(9,7)*y(11);
jac(4,9)=jac(4,9)+jack(9,9)*y(11);
jac(4,10)=jac(4,10)+jack(9,10)*y(11);
jac(4,11)=jac(4,11)+jack(9,11)*y(11);
jac(4,15)=jac(4,15)+jack(9,15)*y(11);
jac(4,11)=jac(4,11)+k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(11,11)=jac(11,11)-k(7);
jac(15,11)=jac(15,11)+k(7);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(11,11)=jac(11,11)-k(6);
jac(15,11)=jac(15,11)+k(6);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~p,r!2).R(e~u!1,r!2) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(2,2)=jac(2,2)-k(1)*y(11);
jac(2,11)=jac(2,11)-k(1)*y(2);
jac(11,2)=jac(11,2)-k(1)*y(11);
jac(11,11)=jac(11,11)-k(1)*y(2);
jac(6,2)=jac(6,2)+k(1)*y(11);
jac(6,11)=jac(6,11)+k(1)*y(2);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> R(e~u,r!1).R(e~u,r!1)

jac(15,1)=jac(15,1)-jack(8,1)*y(15);
jac(15,6)=jac(15,6)-jack(8,6)*y(15);
jac(15,7)=jac(15,7)-jack(8,7)*y(15);
jac(15,15)=jac(15,15)-k(8);
jac(14,1)=jac(14,1)+2*jack(8,1)*y(15);
jac(14,6)=jac(14,6)+2*jack(8,6)*y(15);
jac(14,7)=jac(14,7)+2*jack(8,7)*y(15);
jac(14,15)=jac(14,15)+2*k(8);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> E(r!1).R(e~u!1,r)

jac(15,1)=jac(15,1)-jack(9,1)*y(15);
jac(15,2)=jac(15,2)-jack(9,2)*y(15);
jac(15,4)=jac(15,4)-jack(9,4)*y(15);
jac(15,5)=jac(15,5)-jack(9,5)*y(15);
jac(15,6)=jac(15,6)-jack(9,6)*y(15);
jac(15,7)=jac(15,7)-jack(9,7)*y(15);
jac(15,9)=jac(15,9)-jack(9,9)*y(15);
jac(15,10)=jac(15,10)-jack(9,10)*y(15);
jac(15,11)=jac(15,11)-jack(9,11)*y(15);
jac(15,15)=jac(15,15)-jack(9,15)*y(15);
jac(15,15)=jac(15,15)-k(9);
jac(4,1)=jac(4,1)+jack(9,1)*y(15);
jac(4,2)=jac(4,2)+jack(9,2)*y(15);
jac(4,4)=jac(4,4)+jack(9,4)*y(15);
jac(4,5)=jac(4,5)+jack(9,5)*y(15);
jac(4,6)=jac(4,6)+jack(9,6)*y(15);
jac(4,7)=jac(4,7)+jack(9,7)*y(15);
jac(4,9)=jac(4,9)+jack(9,9)*y(15);
jac(4,10)=jac(4,10)+jack(9,10)*y(15);
jac(4,11)=jac(4,11)+jack(9,11)*y(15);
jac(4,15)=jac(4,15)+jack(9,15)*y(15);
jac(4,15)=jac(4,15)+k(9);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(15,15)=jac(15,15)-k(6);
jac(15,15)=jac(15,15)+k(6);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3)

jac(2,2)=jac(2,2)-k(1)*y(15);
jac(2,15)=jac(2,15)-k(1)*y(2);
jac(15,2)=jac(15,2)-k(1)*y(15);
jac(15,15)=jac(15,15)-k(1)*y(2);
jac(1,2)=jac(1,2)+2*k(1)*y(15);
jac(1,15)=jac(1,15)+2*k(1)*y(2);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> R(e~u,r) + E(r)

jac(15,1)=jac(15,1)-jack(9,1)*y(15);
jac(15,2)=jac(15,2)-jack(9,2)*y(15);
jac(15,4)=jac(15,4)-jack(9,4)*y(15);
jac(15,5)=jac(15,5)-jack(9,5)*y(15);
jac(15,6)=jac(15,6)-jack(9,6)*y(15);
jac(15,7)=jac(15,7)-jack(9,7)*y(15);
jac(15,9)=jac(15,9)-jack(9,9)*y(15);
jac(15,10)=jac(15,10)-jack(9,10)*y(15);
jac(15,11)=jac(15,11)-jack(9,11)*y(15);
jac(15,15)=jac(15,15)-jack(9,15)*y(15);
jac(15,15)=jac(15,15)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(15);
jac(2,2)=jac(2,2)+jack(9,2)*y(15);
jac(2,4)=jac(2,4)+jack(9,4)*y(15);
jac(2,5)=jac(2,5)+jack(9,5)*y(15);
jac(2,6)=jac(2,6)+jack(9,6)*y(15);
jac(2,7)=jac(2,7)+jack(9,7)*y(15);
jac(2,9)=jac(2,9)+jack(9,9)*y(15);
jac(2,10)=jac(2,10)+jack(9,10)*y(15);
jac(2,11)=jac(2,11)+jack(9,11)*y(15);
jac(2,15)=jac(2,15)+jack(9,15)*y(15);
jac(2,15)=jac(2,15)+k(9);
jac(3,1)=jac(3,1)+jack(9,1)*y(15);
jac(3,2)=jac(3,2)+jack(9,2)*y(15);
jac(3,4)=jac(3,4)+jack(9,4)*y(15);
jac(3,5)=jac(3,5)+jack(9,5)*y(15);
jac(3,6)=jac(3,6)+jack(9,6)*y(15);
jac(3,7)=jac(3,7)+jack(9,7)*y(15);
jac(3,9)=jac(3,9)+jack(9,9)*y(15);
jac(3,10)=jac(3,10)+jack(9,10)*y(15);
jac(3,11)=jac(3,11)+jack(9,11)*y(15);
jac(3,15)=jac(3,15)+jack(9,15)*y(15);
jac(3,15)=jac(3,15)+k(9);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r!2).R(e~u,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

jac(15,15)=jac(15,15)-k(2);
jac(10,15)=jac(10,15)+k(2);

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r)

jac(14,1)=jac(14,1)-2*jack(9,1)*y(14)/2;
jac(14,2)=jac(14,2)-2*jack(9,2)*y(14)/2;
jac(14,4)=jac(14,4)-2*jack(9,4)*y(14)/2;
jac(14,5)=jac(14,5)-2*jack(9,5)*y(14)/2;
jac(14,6)=jac(14,6)-2*jack(9,6)*y(14)/2;
jac(14,7)=jac(14,7)-2*jack(9,7)*y(14)/2;
jac(14,9)=jac(14,9)-2*jack(9,9)*y(14)/2;
jac(14,10)=jac(14,10)-2*jack(9,10)*y(14)/2;
jac(14,11)=jac(14,11)-2*jack(9,11)*y(14)/2;
jac(14,15)=jac(14,15)-2*jack(9,15)*y(14)/2;
jac(14,14)=jac(14,14)-2*k(9)/2;
jac(3,1)=jac(3,1)+jack(9,1)*y(14)/2;
jac(3,2)=jac(3,2)+jack(9,2)*y(14)/2;
jac(3,4)=jac(3,4)+jack(9,4)*y(14)/2;
jac(3,5)=jac(3,5)+jack(9,5)*y(14)/2;
jac(3,6)=jac(3,6)+jack(9,6)*y(14)/2;
jac(3,7)=jac(3,7)+jack(9,7)*y(14)/2;
jac(3,9)=jac(3,9)+jack(9,9)*y(14)/2;
jac(3,10)=jac(3,10)+jack(9,10)*y(14)/2;
jac(3,11)=jac(3,11)+jack(9,11)*y(14)/2;
jac(3,15)=jac(3,15)+jack(9,15)*y(14)/2;
jac(3,14)=jac(3,14)+k(9)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r!1).R(e~u,r!1)

jac(14,14)=jac(14,14)-2*k(6)/2;
jac(14,14)=jac(14,14)+2*k(6)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~u,r!1) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(2,2)=jac(2,2)-k(1)*y(14)/2;
jac(2,14)=jac(2,14)-k(1)*y(2)/2;
jac(14,2)=jac(14,2)-2*k(1)*y(14)/2;
jac(14,14)=jac(14,14)-2*k(1)*y(2)/2;
jac(15,2)=jac(15,2)+k(1)*y(14)/2;
jac(15,14)=jac(15,14)+k(1)*y(2)/2;

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r)

jac(14,1)=jac(14,1)-2*jack(9,1)*y(14)/2;
jac(14,2)=jac(14,2)-2*jack(9,2)*y(14)/2;
jac(14,4)=jac(14,4)-2*jack(9,4)*y(14)/2;
jac(14,5)=jac(14,5)-2*jack(9,5)*y(14)/2;
jac(14,6)=jac(14,6)-2*jack(9,6)*y(14)/2;
jac(14,7)=jac(14,7)-2*jack(9,7)*y(14)/2;
jac(14,9)=jac(14,9)-2*jack(9,9)*y(14)/2;
jac(14,10)=jac(14,10)-2*jack(9,10)*y(14)/2;
jac(14,11)=jac(14,11)-2*jack(9,11)*y(14)/2;
jac(14,15)=jac(14,15)-2*jack(9,15)*y(14)/2;
jac(14,14)=jac(14,14)-2*k(9)/2;
jac(3,1)=jac(3,1)+jack(9,1)*y(14)/2;
jac(3,2)=jac(3,2)+jack(9,2)*y(14)/2;
jac(3,4)=jac(3,4)+jack(9,4)*y(14)/2;
jac(3,5)=jac(3,5)+jack(9,5)*y(14)/2;
jac(3,6)=jac(3,6)+jack(9,6)*y(14)/2;
jac(3,7)=jac(3,7)+jack(9,7)*y(14)/2;
jac(3,9)=jac(3,9)+jack(9,9)*y(14)/2;
jac(3,10)=jac(3,10)+jack(9,10)*y(14)/2;
jac(3,11)=jac(3,11)+jack(9,11)*y(14)/2;
jac(3,15)=jac(3,15)+jack(9,15)*y(14)/2;
jac(3,14)=jac(3,14)+k(9)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~u,r!1) -> R(e~u,r!1).R(e~u,r!1)

jac(14,14)=jac(14,14)-2*k(6)/2;
jac(14,14)=jac(14,14)+2*k(6)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~u,r!1) + E(r) -> E(r!1).R(e~u!1,r!2).R(e~u,r!2)

jac(2,2)=jac(2,2)-k(1)*y(14)/2;
jac(2,14)=jac(2,14)-k(1)*y(2)/2;
jac(14,2)=jac(14,2)-2*k(1)*y(14)/2;
jac(14,14)=jac(14,14)-2*k(1)*y(2)/2;
jac(15,2)=jac(15,2)+k(1)*y(14)/2;
jac(15,14)=jac(15,14)+k(1)*y(2)/2;

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r)

jac(13,1)=jac(13,1)-jack(9,1)*y(13);
jac(13,2)=jac(13,2)-jack(9,2)*y(13);
jac(13,4)=jac(13,4)-jack(9,4)*y(13);
jac(13,5)=jac(13,5)-jack(9,5)*y(13);
jac(13,6)=jac(13,6)-jack(9,6)*y(13);
jac(13,7)=jac(13,7)-jack(9,7)*y(13);
jac(13,9)=jac(13,9)-jack(9,9)*y(13);
jac(13,10)=jac(13,10)-jack(9,10)*y(13);
jac(13,11)=jac(13,11)-jack(9,11)*y(13);
jac(13,15)=jac(13,15)-jack(9,15)*y(13);
jac(13,13)=jac(13,13)-k(9);
jac(3,1)=jac(3,1)+jack(9,1)*y(13);
jac(3,2)=jac(3,2)+jack(9,2)*y(13);
jac(3,4)=jac(3,4)+jack(9,4)*y(13);
jac(3,5)=jac(3,5)+jack(9,5)*y(13);
jac(3,6)=jac(3,6)+jack(9,6)*y(13);
jac(3,7)=jac(3,7)+jack(9,7)*y(13);
jac(3,9)=jac(3,9)+jack(9,9)*y(13);
jac(3,10)=jac(3,10)+jack(9,10)*y(13);
jac(3,11)=jac(3,11)+jack(9,11)*y(13);
jac(3,15)=jac(3,15)+jack(9,15)*y(13);
jac(3,13)=jac(3,13)+k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~u,r!1)

jac(13,13)=jac(13,13)-k(7);
jac(14,13)=jac(14,13)+2*k(7);

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~u,r!1)

jac(13,13)=jac(13,13)-k(6);
jac(14,13)=jac(14,13)+2*k(6);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

jac(2,2)=jac(2,2)-k(1)*y(13);
jac(2,13)=jac(2,13)-k(1)*y(2);
jac(13,2)=jac(13,2)-k(1)*y(13);
jac(13,13)=jac(13,13)-k(1)*y(2);
jac(10,2)=jac(10,2)+k(1)*y(13);
jac(10,13)=jac(10,13)+k(1)*y(2);

% rule    : R() -> 
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~p,r)

jac(13,1)=jac(13,1)-jack(9,1)*y(13);
jac(13,2)=jac(13,2)-jack(9,2)*y(13);
jac(13,4)=jac(13,4)-jack(9,4)*y(13);
jac(13,5)=jac(13,5)-jack(9,5)*y(13);
jac(13,6)=jac(13,6)-jack(9,6)*y(13);
jac(13,7)=jac(13,7)-jack(9,7)*y(13);
jac(13,9)=jac(13,9)-jack(9,9)*y(13);
jac(13,10)=jac(13,10)-jack(9,10)*y(13);
jac(13,11)=jac(13,11)-jack(9,11)*y(13);
jac(13,15)=jac(13,15)-jack(9,15)*y(13);
jac(13,13)=jac(13,13)-k(9);
jac(8,1)=jac(8,1)+jack(9,1)*y(13);
jac(8,2)=jac(8,2)+jack(9,2)*y(13);
jac(8,4)=jac(8,4)+jack(9,4)*y(13);
jac(8,5)=jac(8,5)+jack(9,5)*y(13);
jac(8,6)=jac(8,6)+jack(9,6)*y(13);
jac(8,7)=jac(8,7)+jack(9,7)*y(13);
jac(8,9)=jac(8,9)+jack(9,9)*y(13);
jac(8,10)=jac(8,10)+jack(9,10)*y(13);
jac(8,11)=jac(8,11)+jack(9,11)*y(13);
jac(8,15)=jac(8,15)+jack(9,15)*y(13);
jac(8,13)=jac(8,13)+k(9);

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

jac(13,13)=jac(13,13)-k(6);
jac(13,13)=jac(13,13)+k(6);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~p,r!2).R(e~u!1,r!2)

jac(2,2)=jac(2,2)-k(1)*y(13);
jac(2,13)=jac(2,13)-k(1)*y(2);
jac(13,2)=jac(13,2)-k(1)*y(13);
jac(13,13)=jac(13,13)-k(1)*y(2);
jac(11,2)=jac(11,2)+k(1)*y(13);
jac(11,13)=jac(11,13)+k(1)*y(2);

% rule    : R() -> 
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~p,r)

jac(12,1)=jac(12,1)-2*jack(9,1)*y(12)/2;
jac(12,2)=jac(12,2)-2*jack(9,2)*y(12)/2;
jac(12,4)=jac(12,4)-2*jack(9,4)*y(12)/2;
jac(12,5)=jac(12,5)-2*jack(9,5)*y(12)/2;
jac(12,6)=jac(12,6)-2*jack(9,6)*y(12)/2;
jac(12,7)=jac(12,7)-2*jack(9,7)*y(12)/2;
jac(12,9)=jac(12,9)-2*jack(9,9)*y(12)/2;
jac(12,10)=jac(12,10)-2*jack(9,10)*y(12)/2;
jac(12,11)=jac(12,11)-2*jack(9,11)*y(12)/2;
jac(12,15)=jac(12,15)-2*jack(9,15)*y(12)/2;
jac(12,12)=jac(12,12)-2*k(9)/2;
jac(8,1)=jac(8,1)+jack(9,1)*y(12)/2;
jac(8,2)=jac(8,2)+jack(9,2)*y(12)/2;
jac(8,4)=jac(8,4)+jack(9,4)*y(12)/2;
jac(8,5)=jac(8,5)+jack(9,5)*y(12)/2;
jac(8,6)=jac(8,6)+jack(9,6)*y(12)/2;
jac(8,7)=jac(8,7)+jack(9,7)*y(12)/2;
jac(8,9)=jac(8,9)+jack(9,9)*y(12)/2;
jac(8,10)=jac(8,10)+jack(9,10)*y(12)/2;
jac(8,11)=jac(8,11)+jack(9,11)*y(12)/2;
jac(8,15)=jac(8,15)+jack(9,15)*y(12)/2;
jac(8,12)=jac(8,12)+k(9)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

jac(12,12)=jac(12,12)-2*k(7)/2;
jac(13,12)=jac(13,12)+k(7)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

jac(12,12)=jac(12,12)-2*k(6)/2;
jac(13,12)=jac(13,12)+k(6)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~p,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

jac(2,2)=jac(2,2)-k(1)*y(12)/2;
jac(2,12)=jac(2,12)-k(1)*y(2)/2;
jac(12,2)=jac(12,2)-2*k(1)*y(12)/2;
jac(12,12)=jac(12,12)-2*k(1)*y(2)/2;
jac(9,2)=jac(9,2)+k(1)*y(12)/2;
jac(9,12)=jac(9,12)+k(1)*y(2)/2;

% rule    : R() -> 
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~p,r)

jac(12,1)=jac(12,1)-2*jack(9,1)*y(12)/2;
jac(12,2)=jac(12,2)-2*jack(9,2)*y(12)/2;
jac(12,4)=jac(12,4)-2*jack(9,4)*y(12)/2;
jac(12,5)=jac(12,5)-2*jack(9,5)*y(12)/2;
jac(12,6)=jac(12,6)-2*jack(9,6)*y(12)/2;
jac(12,7)=jac(12,7)-2*jack(9,7)*y(12)/2;
jac(12,9)=jac(12,9)-2*jack(9,9)*y(12)/2;
jac(12,10)=jac(12,10)-2*jack(9,10)*y(12)/2;
jac(12,11)=jac(12,11)-2*jack(9,11)*y(12)/2;
jac(12,15)=jac(12,15)-2*jack(9,15)*y(12)/2;
jac(12,12)=jac(12,12)-2*k(9)/2;
jac(8,1)=jac(8,1)+jack(9,1)*y(12)/2;
jac(8,2)=jac(8,2)+jack(9,2)*y(12)/2;
jac(8,4)=jac(8,4)+jack(9,4)*y(12)/2;
jac(8,5)=jac(8,5)+jack(9,5)*y(12)/2;
jac(8,6)=jac(8,6)+jack(9,6)*y(12)/2;
jac(8,7)=jac(8,7)+jack(9,7)*y(12)/2;
jac(8,9)=jac(8,9)+jack(9,9)*y(12)/2;
jac(8,10)=jac(8,10)+jack(9,10)*y(12)/2;
jac(8,11)=jac(8,11)+jack(9,11)*y(12)/2;
jac(8,15)=jac(8,15)+jack(9,15)*y(12)/2;
jac(8,12)=jac(8,12)+k(9)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

jac(12,12)=jac(12,12)-2*k(7)/2;
jac(13,12)=jac(13,12)+k(7)/2;

% rule    : R(e) -> R(e~u)
% reaction: R(e~p,r!1).R(e~p,r!1) -> R(e~u,r!1).R(e~p,r!1)

jac(12,12)=jac(12,12)-2*k(6)/2;
jac(13,12)=jac(13,12)+k(6)/2;

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~p,r!1).R(e~p,r!1) + E(r) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

jac(2,2)=jac(2,2)-k(1)*y(12)/2;
jac(2,12)=jac(2,12)-k(1)*y(2)/2;
jac(12,2)=jac(12,2)-2*k(1)*y(12)/2;
jac(12,12)=jac(12,12)-2*k(1)*y(2)/2;
jac(9,2)=jac(9,2)+k(1)*y(12)/2;
jac(9,12)=jac(9,12)+k(1)*y(2)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> R(e~p,r!1).R(e~p,r!1)

jac(9,1)=jac(9,1)-jack(8,1)*y(9);
jac(9,6)=jac(9,6)-jack(8,6)*y(9);
jac(9,7)=jac(9,7)-jack(8,7)*y(9);
jac(9,9)=jac(9,9)-k(8);
jac(12,1)=jac(12,1)+2*jack(8,1)*y(9);
jac(12,6)=jac(12,6)+2*jack(8,6)*y(9);
jac(12,7)=jac(12,7)+2*jack(8,7)*y(9);
jac(12,9)=jac(12,9)+2*k(8);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> R(e~p,r) + E(r)

jac(9,1)=jac(9,1)-jack(9,1)*y(9);
jac(9,2)=jac(9,2)-jack(9,2)*y(9);
jac(9,4)=jac(9,4)-jack(9,4)*y(9);
jac(9,5)=jac(9,5)-jack(9,5)*y(9);
jac(9,6)=jac(9,6)-jack(9,6)*y(9);
jac(9,7)=jac(9,7)-jack(9,7)*y(9);
jac(9,9)=jac(9,9)-jack(9,9)*y(9);
jac(9,10)=jac(9,10)-jack(9,10)*y(9);
jac(9,11)=jac(9,11)-jack(9,11)*y(9);
jac(9,15)=jac(9,15)-jack(9,15)*y(9);
jac(9,9)=jac(9,9)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(9);
jac(2,2)=jac(2,2)+jack(9,2)*y(9);
jac(2,4)=jac(2,4)+jack(9,4)*y(9);
jac(2,5)=jac(2,5)+jack(9,5)*y(9);
jac(2,6)=jac(2,6)+jack(9,6)*y(9);
jac(2,7)=jac(2,7)+jack(9,7)*y(9);
jac(2,9)=jac(2,9)+jack(9,9)*y(9);
jac(2,10)=jac(2,10)+jack(9,10)*y(9);
jac(2,11)=jac(2,11)+jack(9,11)*y(9);
jac(2,15)=jac(2,15)+jack(9,15)*y(9);
jac(2,9)=jac(2,9)+k(9);
jac(8,1)=jac(8,1)+jack(9,1)*y(9);
jac(8,2)=jac(8,2)+jack(9,2)*y(9);
jac(8,4)=jac(8,4)+jack(9,4)*y(9);
jac(8,5)=jac(8,5)+jack(9,5)*y(9);
jac(8,6)=jac(8,6)+jack(9,6)*y(9);
jac(8,7)=jac(8,7)+jack(9,7)*y(9);
jac(8,9)=jac(8,9)+jack(9,9)*y(9);
jac(8,10)=jac(8,10)+jack(9,10)*y(9);
jac(8,11)=jac(8,11)+jack(9,11)*y(9);
jac(8,15)=jac(8,15)+jack(9,15)*y(9);
jac(8,9)=jac(8,9)+k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~p,r!2).R(e~u!1,r!2)

jac(9,9)=jac(9,9)-k(7);
jac(11,9)=jac(11,9)+k(7);

% rule    : R() -> 
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~p!1,r)

jac(9,1)=jac(9,1)-jack(9,1)*y(9);
jac(9,2)=jac(9,2)-jack(9,2)*y(9);
jac(9,4)=jac(9,4)-jack(9,4)*y(9);
jac(9,5)=jac(9,5)-jack(9,5)*y(9);
jac(9,6)=jac(9,6)-jack(9,6)*y(9);
jac(9,7)=jac(9,7)-jack(9,7)*y(9);
jac(9,9)=jac(9,9)-jack(9,9)*y(9);
jac(9,10)=jac(9,10)-jack(9,10)*y(9);
jac(9,11)=jac(9,11)-jack(9,11)*y(9);
jac(9,15)=jac(9,15)-jack(9,15)*y(9);
jac(9,9)=jac(9,9)-k(9);
jac(5,1)=jac(5,1)+jack(9,1)*y(9);
jac(5,2)=jac(5,2)+jack(9,2)*y(9);
jac(5,4)=jac(5,4)+jack(9,4)*y(9);
jac(5,5)=jac(5,5)+jack(9,5)*y(9);
jac(5,6)=jac(5,6)+jack(9,6)*y(9);
jac(5,7)=jac(5,7)+jack(9,7)*y(9);
jac(5,9)=jac(5,9)+jack(9,9)*y(9);
jac(5,10)=jac(5,10)+jack(9,10)*y(9);
jac(5,11)=jac(5,11)+jack(9,11)*y(9);
jac(5,15)=jac(5,15)+jack(9,15)*y(9);
jac(5,9)=jac(5,9)+k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

jac(9,9)=jac(9,9)-k(7);
jac(10,9)=jac(10,9)+k(7);

% rule    : R(e) -> R(e~u)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) -> E(r!1).R(e~u,r!2).R(e~p!1,r!2)

jac(9,9)=jac(9,9)-k(6);
jac(10,9)=jac(10,9)+k(6);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: E(r!1).R(e~p,r!2).R(e~p!1,r!2) + E(r) -> E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3)

jac(2,2)=jac(2,2)-k(1)*y(9);
jac(2,9)=jac(2,9)-k(1)*y(2);
jac(9,2)=jac(9,2)-k(1)*y(9);
jac(9,9)=jac(9,9)-k(1)*y(2);
jac(7,2)=jac(7,2)+2*k(1)*y(9);
jac(7,9)=jac(7,9)+2*k(1)*y(2);

% rule    : E() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

jac(7,1)=jac(7,1)-2*jack(8,1)*y(7)/2;
jac(7,6)=jac(7,6)-2*jack(8,6)*y(7)/2;
jac(7,7)=jac(7,7)-2*jack(8,7)*y(7)/2;
jac(7,7)=jac(7,7)-2*k(8)/2;
jac(9,1)=jac(9,1)+jack(8,1)*y(7)/2;
jac(9,6)=jac(9,6)+jack(8,6)*y(7)/2;
jac(9,7)=jac(9,7)+jack(8,7)*y(7)/2;
jac(9,7)=jac(9,7)+k(8)/2;

% rule    : E() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p,r!2).R(e~p!1,r!2)

jac(7,1)=jac(7,1)-2*jack(8,1)*y(7)/2;
jac(7,6)=jac(7,6)-2*jack(8,6)*y(7)/2;
jac(7,7)=jac(7,7)-2*jack(8,7)*y(7)/2;
jac(7,7)=jac(7,7)-2*k(8)/2;
jac(9,1)=jac(9,1)+jack(8,1)*y(7)/2;
jac(9,6)=jac(9,6)+jack(8,6)*y(7)/2;
jac(9,7)=jac(9,7)+jack(8,7)*y(7)/2;
jac(9,7)=jac(9,7)+k(8)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r) + E(r)

jac(7,1)=jac(7,1)-2*jack(9,1)*y(7)/2;
jac(7,2)=jac(7,2)-2*jack(9,2)*y(7)/2;
jac(7,4)=jac(7,4)-2*jack(9,4)*y(7)/2;
jac(7,5)=jac(7,5)-2*jack(9,5)*y(7)/2;
jac(7,6)=jac(7,6)-2*jack(9,6)*y(7)/2;
jac(7,7)=jac(7,7)-2*jack(9,7)*y(7)/2;
jac(7,9)=jac(7,9)-2*jack(9,9)*y(7)/2;
jac(7,10)=jac(7,10)-2*jack(9,10)*y(7)/2;
jac(7,11)=jac(7,11)-2*jack(9,11)*y(7)/2;
jac(7,15)=jac(7,15)-2*jack(9,15)*y(7)/2;
jac(7,7)=jac(7,7)-2*k(9)/2;
jac(2,1)=jac(2,1)+jack(9,1)*y(7)/2;
jac(2,2)=jac(2,2)+jack(9,2)*y(7)/2;
jac(2,4)=jac(2,4)+jack(9,4)*y(7)/2;
jac(2,5)=jac(2,5)+jack(9,5)*y(7)/2;
jac(2,6)=jac(2,6)+jack(9,6)*y(7)/2;
jac(2,7)=jac(2,7)+jack(9,7)*y(7)/2;
jac(2,9)=jac(2,9)+jack(9,9)*y(7)/2;
jac(2,10)=jac(2,10)+jack(9,10)*y(7)/2;
jac(2,11)=jac(2,11)+jack(9,11)*y(7)/2;
jac(2,15)=jac(2,15)+jack(9,15)*y(7)/2;
jac(2,7)=jac(2,7)+k(9)/2;
jac(5,1)=jac(5,1)+jack(9,1)*y(7)/2;
jac(5,2)=jac(5,2)+jack(9,2)*y(7)/2;
jac(5,4)=jac(5,4)+jack(9,4)*y(7)/2;
jac(5,5)=jac(5,5)+jack(9,5)*y(7)/2;
jac(5,6)=jac(5,6)+jack(9,6)*y(7)/2;
jac(5,7)=jac(5,7)+jack(9,7)*y(7)/2;
jac(5,9)=jac(5,9)+jack(9,9)*y(7)/2;
jac(5,10)=jac(5,10)+jack(9,10)*y(7)/2;
jac(5,11)=jac(5,11)+jack(9,11)*y(7)/2;
jac(5,15)=jac(5,15)+jack(9,15)*y(7)/2;
jac(5,7)=jac(5,7)+k(9)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(7,7)=jac(7,7)-2*k(7)/2;
jac(6,7)=jac(6,7)+k(7)/2;

% rule    : R() -> 
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~p!1,r) + E(r)

jac(7,1)=jac(7,1)-2*jack(9,1)*y(7)/2;
jac(7,2)=jac(7,2)-2*jack(9,2)*y(7)/2;
jac(7,4)=jac(7,4)-2*jack(9,4)*y(7)/2;
jac(7,5)=jac(7,5)-2*jack(9,5)*y(7)/2;
jac(7,6)=jac(7,6)-2*jack(9,6)*y(7)/2;
jac(7,7)=jac(7,7)-2*jack(9,7)*y(7)/2;
jac(7,9)=jac(7,9)-2*jack(9,9)*y(7)/2;
jac(7,10)=jac(7,10)-2*jack(9,10)*y(7)/2;
jac(7,11)=jac(7,11)-2*jack(9,11)*y(7)/2;
jac(7,15)=jac(7,15)-2*jack(9,15)*y(7)/2;
jac(7,7)=jac(7,7)-2*k(9)/2;
jac(2,1)=jac(2,1)+jack(9,1)*y(7)/2;
jac(2,2)=jac(2,2)+jack(9,2)*y(7)/2;
jac(2,4)=jac(2,4)+jack(9,4)*y(7)/2;
jac(2,5)=jac(2,5)+jack(9,5)*y(7)/2;
jac(2,6)=jac(2,6)+jack(9,6)*y(7)/2;
jac(2,7)=jac(2,7)+jack(9,7)*y(7)/2;
jac(2,9)=jac(2,9)+jack(9,9)*y(7)/2;
jac(2,10)=jac(2,10)+jack(9,10)*y(7)/2;
jac(2,11)=jac(2,11)+jack(9,11)*y(7)/2;
jac(2,15)=jac(2,15)+jack(9,15)*y(7)/2;
jac(2,7)=jac(2,7)+k(9)/2;
jac(5,1)=jac(5,1)+jack(9,1)*y(7)/2;
jac(5,2)=jac(5,2)+jack(9,2)*y(7)/2;
jac(5,4)=jac(5,4)+jack(9,4)*y(7)/2;
jac(5,5)=jac(5,5)+jack(9,5)*y(7)/2;
jac(5,6)=jac(5,6)+jack(9,6)*y(7)/2;
jac(5,7)=jac(5,7)+jack(9,7)*y(7)/2;
jac(5,9)=jac(5,9)+jack(9,9)*y(7)/2;
jac(5,10)=jac(5,10)+jack(9,10)*y(7)/2;
jac(5,11)=jac(5,11)+jack(9,11)*y(7)/2;
jac(5,15)=jac(5,15)+jack(9,15)*y(7)/2;
jac(5,7)=jac(5,7)+k(9)/2;

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(7,7)=jac(7,7)-2*k(7)/2;
jac(6,7)=jac(6,7)+k(7)/2;

% rule    : R() -> 
% reaction: R(e~p,r) -> 

jac(8,1)=jac(8,1)-jack(9,1)*y(8);
jac(8,2)=jac(8,2)-jack(9,2)*y(8);
jac(8,4)=jac(8,4)-jack(9,4)*y(8);
jac(8,5)=jac(8,5)-jack(9,5)*y(8);
jac(8,6)=jac(8,6)-jack(9,6)*y(8);
jac(8,7)=jac(8,7)-jack(9,7)*y(8);
jac(8,9)=jac(8,9)-jack(9,9)*y(8);
jac(8,10)=jac(8,10)-jack(9,10)*y(8);
jac(8,11)=jac(8,11)-jack(9,11)*y(8);
jac(8,15)=jac(8,15)-jack(9,15)*y(8);
jac(8,8)=jac(8,8)-k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: R(e~p,r) -> R(e~u,r)

jac(8,8)=jac(8,8)-k(7);
jac(3,8)=jac(3,8)+k(7);

% rule    : R(e) -> R(e~u)
% reaction: R(e~p,r) -> R(e~u,r)

jac(8,8)=jac(8,8)-k(6);
jac(3,8)=jac(3,8)+k(6);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~p,r) + E(r) -> E(r!1).R(e~p!1,r)

jac(2,2)=jac(2,2)-k(1)*y(8);
jac(2,8)=jac(2,8)-k(1)*y(2);
jac(8,2)=jac(8,2)-k(1)*y(8);
jac(8,8)=jac(8,8)-k(1)*y(2);
jac(5,2)=jac(5,2)+k(1)*y(8);
jac(5,8)=jac(5,8)+k(1)*y(2);

% rule    : E() -> 
% reaction: E(r!1).R(e~p!1,r) -> R(e~p,r)

jac(5,1)=jac(5,1)-jack(8,1)*y(5);
jac(5,6)=jac(5,6)-jack(8,6)*y(5);
jac(5,7)=jac(5,7)-jack(8,7)*y(5);
jac(5,5)=jac(5,5)-k(8);
jac(8,1)=jac(8,1)+jack(8,1)*y(5);
jac(8,6)=jac(8,6)+jack(8,6)*y(5);
jac(8,7)=jac(8,7)+jack(8,7)*y(5);
jac(8,5)=jac(8,5)+k(8);

% rule    : R() -> 
% reaction: E(r!1).R(e~p!1,r) -> E(r)

jac(5,1)=jac(5,1)-jack(9,1)*y(5);
jac(5,2)=jac(5,2)-jack(9,2)*y(5);
jac(5,4)=jac(5,4)-jack(9,4)*y(5);
jac(5,5)=jac(5,5)-jack(9,5)*y(5);
jac(5,6)=jac(5,6)-jack(9,6)*y(5);
jac(5,7)=jac(5,7)-jack(9,7)*y(5);
jac(5,9)=jac(5,9)-jack(9,9)*y(5);
jac(5,10)=jac(5,10)-jack(9,10)*y(5);
jac(5,11)=jac(5,11)-jack(9,11)*y(5);
jac(5,15)=jac(5,15)-jack(9,15)*y(5);
jac(5,5)=jac(5,5)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(5);
jac(2,2)=jac(2,2)+jack(9,2)*y(5);
jac(2,4)=jac(2,4)+jack(9,4)*y(5);
jac(2,5)=jac(2,5)+jack(9,5)*y(5);
jac(2,6)=jac(2,6)+jack(9,6)*y(5);
jac(2,7)=jac(2,7)+jack(9,7)*y(5);
jac(2,9)=jac(2,9)+jack(9,9)*y(5);
jac(2,10)=jac(2,10)+jack(9,10)*y(5);
jac(2,11)=jac(2,11)+jack(9,11)*y(5);
jac(2,15)=jac(2,15)+jack(9,15)*y(5);
jac(2,5)=jac(2,5)+k(9);

% rule    : R(e~p?) -> R(e~u?)
% reaction: E(r!1).R(e~p!1,r) -> E(r!1).R(e~u!1,r)

jac(5,5)=jac(5,5)-k(7);
jac(4,5)=jac(4,5)+k(7);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~p!1,r) + E(r!1).R(e~p!1,r) -> E(r!1).R(e~p!1,r!2).R(e~p!3,r!2).E(r!3)

jac(5,5)=jac(5,5)-k(5)*y(5);
jac(5,5)=jac(5,5)-k(5)*y(5);
jac(5,5)=jac(5,5)-k(5)*y(5);
jac(5,5)=jac(5,5)-k(5)*y(5);
jac(7,5)=jac(7,5)+2*k(5)*y(5);
jac(7,5)=jac(7,5)+2*k(5)*y(5);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~p!1,r) + E(r!1).R(e~u!1,r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(4,4)=jac(4,4)-k(5)*y(5);
jac(4,5)=jac(4,5)-k(5)*y(4);
jac(5,4)=jac(5,4)-k(5)*y(5);
jac(5,5)=jac(5,5)-k(5)*y(4);
jac(6,4)=jac(6,4)+k(5)*y(5);
jac(6,5)=jac(6,5)+k(5)*y(4);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~u!1,r) + E(r!1).R(e~p!1,r) -> E(r!1).R(e~u!1,r!2).R(e~p!3,r!2).E(r!3)

jac(5,5)=jac(5,5)-k(5)*y(4);
jac(5,4)=jac(5,4)-k(5)*y(5);
jac(4,5)=jac(4,5)-k(5)*y(4);
jac(4,4)=jac(4,4)-k(5)*y(5);
jac(6,5)=jac(6,5)+k(5)*y(4);
jac(6,4)=jac(6,4)+k(5)*y(5);

% rule    : E() -> 
% reaction: E(r!1).R(e~u!1,r) -> R(e~u,r)

jac(4,1)=jac(4,1)-jack(8,1)*y(4);
jac(4,6)=jac(4,6)-jack(8,6)*y(4);
jac(4,7)=jac(4,7)-jack(8,7)*y(4);
jac(4,4)=jac(4,4)-k(8);
jac(3,1)=jac(3,1)+jack(8,1)*y(4);
jac(3,6)=jac(3,6)+jack(8,6)*y(4);
jac(3,7)=jac(3,7)+jack(8,7)*y(4);
jac(3,4)=jac(3,4)+k(8);

% rule    : R() -> 
% reaction: E(r!1).R(e~u!1,r) -> E(r)

jac(4,1)=jac(4,1)-jack(9,1)*y(4);
jac(4,2)=jac(4,2)-jack(9,2)*y(4);
jac(4,4)=jac(4,4)-jack(9,4)*y(4);
jac(4,5)=jac(4,5)-jack(9,5)*y(4);
jac(4,6)=jac(4,6)-jack(9,6)*y(4);
jac(4,7)=jac(4,7)-jack(9,7)*y(4);
jac(4,9)=jac(4,9)-jack(9,9)*y(4);
jac(4,10)=jac(4,10)-jack(9,10)*y(4);
jac(4,11)=jac(4,11)-jack(9,11)*y(4);
jac(4,15)=jac(4,15)-jack(9,15)*y(4);
jac(4,4)=jac(4,4)-k(9);
jac(2,1)=jac(2,1)+jack(9,1)*y(4);
jac(2,2)=jac(2,2)+jack(9,2)*y(4);
jac(2,4)=jac(2,4)+jack(9,4)*y(4);
jac(2,5)=jac(2,5)+jack(9,5)*y(4);
jac(2,6)=jac(2,6)+jack(9,6)*y(4);
jac(2,7)=jac(2,7)+jack(9,7)*y(4);
jac(2,9)=jac(2,9)+jack(9,9)*y(4);
jac(2,10)=jac(2,10)+jack(9,10)*y(4);
jac(2,11)=jac(2,11)+jack(9,11)*y(4);
jac(2,15)=jac(2,15)+jack(9,15)*y(4);
jac(2,4)=jac(2,4)+k(9);

% rule    : R(e~u!1), E(r!1) -> R(e~p!1), E(r!1)
% reaction: E(r!1).R(e~u!1,r) -> E(r!1).R(e~p!1,r)

jac(4,4)=jac(4,4)-k(2);
jac(5,4)=jac(5,4)+k(2);

% rule    : R(e!_,r), R(e!r.E,r) -> R(e!_,r!1), R(e!r.E,r!1)
% reaction: E(r!1).R(e~u!1,r) + E(r!1).R(e~u!1,r) -> E(r!1).R(e~u!1,r!2).R(e~u!3,r!2).E(r!3)

jac(4,4)=jac(4,4)-k(5)*y(4);
jac(4,4)=jac(4,4)-k(5)*y(4);
jac(4,4)=jac(4,4)-k(5)*y(4);
jac(4,4)=jac(4,4)-k(5)*y(4);
jac(1,4)=jac(1,4)+2*k(5)*y(4);
jac(1,4)=jac(1,4)+2*k(5)*y(4);

% rule    : E() -> 
% reaction: E(r) -> 

jac(2,1)=jac(2,1)-jack(8,1)*y(2);
jac(2,6)=jac(2,6)-jack(8,6)*y(2);
jac(2,7)=jac(2,7)-jack(8,7)*y(2);
jac(2,2)=jac(2,2)-k(8);

% rule    : E(r), R(e) -> E(r!1), R(e!1)
% reaction: R(e~u,r) + E(r) -> E(r!1).R(e~u!1,r)

jac(2,2)=jac(2,2)-k(1)*y(3);
jac(2,3)=jac(2,3)-k(1)*y(2);
jac(3,2)=jac(3,2)-k(1)*y(3);
jac(3,3)=jac(3,3)-k(1)*y(2);
jac(4,2)=jac(4,2)+k(1)*y(3);
jac(4,3)=jac(4,3)+k(1)*y(2);

% rule    : R() -> 
% reaction: R(e~u,r) -> 

jac(3,1)=jac(3,1)-jack(9,1)*y(3);
jac(3,2)=jac(3,2)-jack(9,2)*y(3);
jac(3,4)=jac(3,4)-jack(9,4)*y(3);
jac(3,5)=jac(3,5)-jack(9,5)*y(3);
jac(3,6)=jac(3,6)-jack(9,6)*y(3);
jac(3,7)=jac(3,7)-jack(9,7)*y(3);
jac(3,9)=jac(3,9)-jack(9,9)*y(3);
jac(3,10)=jac(3,10)-jack(9,10)*y(3);
jac(3,11)=jac(3,11)-jack(9,11)*y(3);
jac(3,15)=jac(3,15)-jack(9,15)*y(3);
jac(3,3)=jac(3,3)-k(9);

% rule    : R(e) -> R(e~u)
% reaction: R(e~u,r) -> R(e~u,r)

jac(3,3)=jac(3,3)-k(6);
jac(3,3)=jac(3,3)+k(6);

% rule    :  -> R(e~u,r)
% reaction:  -> R(e~u,r)


% rule    :  -> E(r)
% reaction:  -> E(r)

end


function obs=ode_obs(y)

global nobs
global var
obs=zeros(nobs,1);

t = y(16);
var(2)=y(1)+2*y(6)+y(7); % r1: E() ->  @ |E(r[1]), R(e[1] r[2]), R(r[2] e[3]), E(r[3])|_rate
var(1)=y(2)+y(4)+y(5)+y(15)+y(10)+y(11)+y(9)+y(1)+2*y(6)+y(7); % d

obs(1)=t; % [T]

end


main();
