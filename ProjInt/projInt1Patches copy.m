%{
% Script to test the time integration function projInt1() 
% on patch simulation of Burgers PDE.  
% AJR, Oct 2017
%!TEX root = ../equationFreeDoc.tex
\subsection{Projective integration of patch scheme}
\label{sec:pips}

Seek to simulate the nonlinear diffusion \pde\
\begin{equation*}
\D tu+cu\D xu=\DD xu\quad \text{for $2\pi$-periodic }u,
\end{equation*}
for \(c=30\), and
with various initial conditions.
Use a patch scheme to only compute on part of space as shown in \autoref{fig:pit1psu}.

\begin{figure}
\centering
\caption{\label{fig:pit1psu}field \(u(x,t)\) tests basic projective integration of a basic patch scheme of Burgers' \pde.}
\includegraphics[width=\linewidth]{ProjInt/projInt1PatchesU}
\end{figure}

Function header and variables needed by discrete patch scheme.
\begin{matlab}
%}
function projInt1Patches
global dx H ratio j jp jm i I
%{
\end{matlab}

Set parameters of the patch scheme: 
the number of patches;  
number of micro-grid points within each patch;
the patch size to macroscale ratio.
\begin{matlab}
%}
nPatch=8
nMicro=11
ratio=0.1
%{
\end{matlab}
The points in the microscale, sub-patch, grid are indexed by~\verb|i|, and \verb|I| is the index of the mid-patch value used for coupling patches.
The macroscale patches are indexed by~\verb|j| and the neighbours by \verb|jp| and \verb|jm|.
\begin{matlab}
%}
i=2:nMicro-1; % microscopic internal points for PDE
I=round((nMicro+1)/2); % midpoint of each patch
j=1:nPatch; jp=mod(j,nPatch)+1; jm=mod(j-2,nPatch)+1; % patch index
%{
\end{matlab}
Make the spatial grid of patches centred at~\(X_j\) and of half-size \(h=rH\).
To suit Neumann boundary conditions on the patches make the micro-grid straddle the patch boundary by setting \(dx=2h/(n_\mu-2)\).
In order for the microscale simulation to be stable, we should have \(dt\ll dx^2\).
Then generate the microscale grid locations for all patches: \(x_{ij}\)~is the location of the \(i\)th~micro-point in the \(j\)th~patch.
\begin{matlab}
%}
X=linspace(0,2*pi,nPatch+1); X=X(j); % patch mid-points
H=X(2)-X(1) % spacing of mid-patch points
dx=2*ratio*H/(nMicro-2) % micro-grid size 
dt=0.4*dx^2; % micro-time-step
x=bsxfun(@plus,dx*(-I+1:I-1)',X); % micro-grids
%{
\end{matlab}

Set the initial condition of a sine wave with random perturbations.
\begin{matlab}
%}
u0=0.3*(1+sin(x(i,:)))+0.03*randn(size(x(i,:)));
%{
\end{matlab}
Set the desired macroscale time-steps over the time domain.
\begin{matlab}
%}
ts=linspace(0,0.45,10)
%{
\end{matlab}

Projectively integrate in time with: 
\dmd\ projection of rank \(\verb|nPatch|+1\); 
guessed microscale time-step~\verb|dt|; and 
guessed numbers of transient and slow steps.
\begin{matlab}
%}
[us,uss,tss]=projInt1(@dudt,u0(:),ts,nPatch+1,dt,[20 nPatch*2]);
%{
\end{matlab}
Plot the macroscale predictions to draw \autoref{fig:pit1psu}, in groups of five in a plot.
\begin{matlab}
%}
U=nan(nPatch*nMicro,size(us,2));
ij=bsxfun(@plus,i',nMicro*(j-1));
U(ij(:),:)=us;
figure(1)
k=length(ts); ls=nan(5,ceil(k/5)); ls(1:k)=1:k;
for k=1:size(ls,2)
  subplot(size(ls,2),1,k)
  plot(x(:),U(:,ls(:,k)),'.')
  ylabel('u(x,t)')
  legend(num2str(ts(ls(:,k))'))
end
xlabel('space x')
%matlab2tikz('projInt1Test1u.ltx','noSize',true)
print('-depsc2','projInt1PatchesU')
%{
\end{matlab}
Also plot a surface of the microscale bursts as shown in \autoref{fig:piBurgersMicro}.
\begin{figure}
\centering
\caption{\label{fig:piBurgersMicro}stereo pair of the field \(u(x,t)\) during each of the microscale bursts used in the projective integration.}
\includegraphics[width=\linewidth]{ProjInt/projInt1PatchesMicro}
\end{figure}
\begin{matlab}
%}
U=nan(nPatch*nMicro,size(uss,2));
U(ij(:),:)=uss;
figure(2)
for k=1:2, subplot(2,2,k)
  surf(tss,x(:),U)
  ylabel('x'),xlabel('t'),zlabel('u(x,t)')
  view(121-4*k,45)
end
print('-depsc2','projInt1PatchesMicro')
%{
\end{matlab}

End the main function (not needed for new enough Matlab).
\begin{matlab}
%}
end
%{
\end{matlab}


\paragraph{Discretisation of Burgers PDE in coupled patches}
Code the simple centred difference discretisation of the nonlinear Burgers' \pde, \(2\pi\)-periodic in space.
\begin{matlab}
%}
function ut=dudt(u,t)
global dx H ratio j jp jm i I
nPatch=j(end);
u=[nan(1,nPatch);reshape(u,[],nPatch);nan(1,nPatch)];
%{
\end{matlab}
Compute differences of the mid-patch values.
\begin{matlab}
%}
dmu=(u(I,jp)-u(I,jm))/2; % \mu\delta
ddu=(u(I,jp)-2*u(I,j)+u(I,jm)); % \delta^2
dddmu=dmu(jp)-2*dmu(j)+dmu(jm);
ddddu=ddu(jp)-2*ddu(j)+ddu(jm);
%{
\end{matlab}
Use these differences to interpolate fluxes on the patch boundaries and hence set the edge values on the patch.
\begin{matlab}
%}
u(end,j)=u(end-1,j)+(dx/H)*(dmu+ratio*ddu ...
	-(dddmu*(1/6-ratio^2/2)+ddddu*ratio*(1/12-ratio^2/6)));
u(1,j)=u(2,j)      -(dx/H)*(dmu-ratio*ddu ...
	-(dddmu*(1/6-ratio^2/2)-ddddu*ratio*(1/12-ratio^2/6)));	
%{
\end{matlab}
Code Burgers' \pde\ in the interior of every patch.
\begin{matlab}
%}
ut=(u(i+1,j)-2*u(i,j)+u(i-1,j))/dx^2 ...
   -30*u(i,j).*(u(i+1,j)-u(i-1,j))/(2*dx);
ut=ut(:);
end
%{
\end{matlab}
%}
