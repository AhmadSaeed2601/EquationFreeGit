%Simulate Burgers' PDE on patches as an example and simple
%test of smoothPatch1()
%AJR, Nov 2017
%!TEX root = ../equationFreeDoc.tex
%{
\subsection{\texttt{BurgersExample}: simulate Burgers' PDE on patches}
\label{sec:BurgersExample}
\localtableofcontents

\begin{figure}
\centering
\caption{\label{fig:ps1BurgersCtsU}field \(u(x,t)\) tests the patch scheme function applied to Burgers' \pde.}
\includegraphics[width=\linewidth]{Patch/ps1BurgersCtsU}
\end{figure}%
\autoref{fig:ps1BurgersCtsU} shows an example simulation in time generated by the patch scheme function applied to Burgers' \pde.
The inter-patch coupling is realised by fourth-order interpolation to the patch edges of the mid-patch values.


Establish global data struct for Burgers' \pde\ solved on \(2\pi\)-periodic domain, with eight patches, each patch of half-size ratio~\(0.2\),  with seven points within each patch, and say fourth order\slash spectral interpolation provides values for the inter-patch coupling conditions.
\begin{matlab}
%}
clear all, close all
global patches
nPatch=8
ratio=0.2
nSubP=7
Len=2*pi;
interpOrd=0
makePatches(@burgerspde,[0,Len],nan,nPatch,interpOrd,ratio,nSubP);
%{
\end{matlab}

Set an initial condition, and check evaluation of the time derivative.
\begin{matlab}
%}
u0=0.3*(1+sin(patches.x))+0.05*randn(size(patches.x));
dudt=patchSmooth1(0,u0(:));
%{
\end{matlab}

\paragraph{Conventional integration in time}
Integrate in time using standard \script\ functions.
\begin{matlab}
%}
ts=linspace(0,0.5,60);
if exist('OCTAVE_VERSION', 'builtin') % Octave version
   ucts=lsode(@(u,t) patchSmooth1(t,u),u0(:),ts);
else % Matlab version
   [ts,ucts]=ode15s(@patchSmooth1,ts([1 end]),u0(:));
end
%{
\end{matlab}

Plot the simulation, but here use only the microscale values interior to the patches.
Use \verb|nan| in the \(x\)-edges to leave gaps.
\begin{matlab}
%}
figure(1),clf
xs=patches.x; xs([1 end],:)=nan;
surf(ts,xs(:),ucts')
title('Use standard integrators for stiff systems')
xlabel('time t'), ylabel('space x'), zlabel('interior field u(x,t)')
view(60,40)
print('-depsc2','ps1BurgersCtsU')
%{
\end{matlab}
%Alternatively, plot all the patch values via interpolation.
%Usually want to seperate the patches by gaps using \verb|nan|.
%\begin{matlab}
%%}
%figure(2),clf()
%u=patchEdgeInt1(ucts'); 
%u=[u; nan(1,size(u,2),size(u,3))];
%xs=[patches.x; nan(1,size(patches.x,2))]; 
%surf(ts,xs(:),reshape(u,[],length(ts)))
%title('Use standard integrators for stiff systems')
%xlabel('time t'), ylabel('space x'), zlabel('field u(x,t)')
%view(60,40)
%%{
%\end{matlab}



\paragraph{Use projective integration}
\begin{figure}
\centering
\caption{\label{fig:ps1BurgersU}field \(u(x,t)\) tests basic projective integration of the patch scheme function applied to Burgers' \pde.}
\includegraphics[width=\linewidth]{Patch/ps1BurgersU}
\end{figure}%
Now wrap around the patch time derivative function, \verb|patchSmooth1|, the projective integration function for patch simulations as illustrated by \autoref{fig:ps1BurgersU}.

Mark that edge of patches are not to be used in the projective extrapolation by setting initial values to \nan.
\begin{matlab}
%}
u0([1 end],:)=nan;
%{
\end{matlab}
Set the desired macro- and micro-scale time-steps over the time domain.
\begin{matlab}
%}
ts=linspace(0,0.45,10)
bT=2*(ratio*Len/nPatch/(nSubP/2-1))^2;
%{
\end{matlab}

Projectively integrate in time with: 
\textsc{dmd} projection of rank \(\verb|nPatch|+1\); 
guessed microscale time-step~\verb|dt|; and 
guessed numbers of transient and slow steps.
\begin{matlab}
%}
addpath('../ProjInt')
[us,tss,uss]=PIRK2(@patchBurst,bT,ts,u0(:));
%{
\end{matlab}
Plot the macroscale predictions to draw \autoref{fig:ps1BurgersU}, in groups of five in a plot.
\begin{matlab}
%}
figure(2),clf
k=length(ts); ls=nan(5,ceil(k/5)); ls(1:k)=1:k;
for k=1:size(ls,2)
  subplot(size(ls,2),1,k)
  plot(patches.x(:),us(ls(:,k),:)')
  ylabel('u(x,t)')
  legend(num2str(ts(ls(:,k))'))
end
xlabel('space x')
print('-depsc2','ps1BurgersU')
%{
\end{matlab}
Also plot a surface of the microscale bursts as shown in \autoref{fig:ps1BurgersMicro}.
\begin{figure}
\centering
\caption{\label{fig:ps1BurgersMicro}stereo pair of the field \(u(x,t)\) during each of the microscale bursts used in the projective integration.}
\includegraphics[width=\linewidth]{Patch/ps1BurgersMicro}
\end{figure}
\begin{matlab}
%}
figure(3),clf
for k=1:2, subplot(2,2,k)
  surf(tss,patches.x(:),uss' ,'EdgeColor','none')
  ylabel('x'),xlabel('t'),zlabel('u(x,t)')
  axis tight, view(121-4*k,45)
end
print('-depsc2','ps1BurgersMicro')
%{
\end{matlab}






\subsubsection{\texttt{burgerspde()}: code the PDE inside patches}
This function codes the lattice differential equations inside the patches.
\begin{matlab}
%}
function ut=burgerspde(t,u,x)
dx=x(2)-x(1);
ut=nan(size(u));
i=2:size(u,1)-1;
ut(i,:)=diff(u,2)/dx^2 ...
   -30*u(i,:).*(u(i+1,:)-u(i-1,:))/(2*dx);
end
%{
\end{matlab}
\subsubsection{\texttt{patchBurst()}: code a burst of the patches}
\begin{matlab}
%}
function [ts, us] = patchBurst(ti, ui, bT) 
    [ts, us] = ode23(@patchSmooth1, [ti ti+bT], ui);
end
%{
\end{matlab}

Fin.
%}
