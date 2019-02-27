% Simulate a microscale space-time map of Burgers' PDE
% discretised.  Simulate on spatial patches, and via
% projective integration.
% AJR, Nov 2017 -- Feb 2019
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\section{\texttt{BurgersExample}: simulate Burgers' PDE on patches}
\label{sec:BurgersExample}
\localtableofcontents

\cref{fig:config1Burgers} shows an example simulation in
time generated by the patch scheme function applied to
Burgers' \pde. This code similarly applies the Equation-Free
functions to a microscale space-time map
(\cref{fig:BurgersMapU}), a map that happens to be
derived as a microscale space-time discretisation of
Burgers'~\pde.  Then this example applies projective
integration to simulate further in time.

The first part of the script implements the following
gap-tooth scheme (left-right arrows denote function
recursion).
\begin{enumerate}\def\itemsep{-1.5ex}
\item configPatches1 
\item burgerBurst \into patchSmooth1 \into burgersMap
\item process results
\end{enumerate}


\begin{figure}
\centering \caption{\label{fig:BurgersMapU}a short time
simulation of the Burgers' map (\cref{sec:burgersMap}) on
patches in space. It requires many very small time-steps
only just visible in this mesh.}
\includegraphics[scale=0.9]{BurgersMapU}
\end{figure}%


\subsection{Script code to simulate a microscale space-time map}

Establish global data struct for the Burgers' map
(\cref{sec:burgersMap}) solved on \(2\pi\)-periodic domain,
with eight patches, each patch of half-size ratio~\(0.2\), 
with seven points within each patch, and say fourth-order
interpolation provides edge-values that couple the patches.
\begin{matlab}
%}
clear all
global patches
nPatch = 8
ratio = 0.2
nSubP = 7
interpOrd = 4
Len = 2*pi
configPatches1(@burgersMap,[0 Len],nan,nPatch,interpOrd,ratio,nSubP);
%{
\end{matlab}
Set an initial condition, and simulate a burst of the
microscale space-time map over a time~\(0.2\) using the
function \verb|burgerBurst()| (\cref{sec:burgerBurst}).
\begin{matlab}
%}
u0 = 0.4*(1+sin(patches.x))+0.1*randn(size(patches.x));
[ts,us] = burgerBurst(0,u0,0.2);
%{
\end{matlab}
Plot the simulation. Use only the microscale values interior
to the patches by setting the edges to \verb|nan| in order
to leave gaps.
\begin{matlab}
%}
figure(1),clf
xs = patches.x;  xs([1 end],:) = nan;
mesh(ts,xs(:),us')
xlabel('time t'), ylabel('space x'), zlabel('u(x,t)')
view(105,45)
%{
\end{matlab}
Save the plot to file to form \cref{fig:BurgersMapU}.
\begin{matlab}
%}
set(gcf,'paperposition',[0 0 14 10])
print('-depsc2','BurgersMapU')
%{
\end{matlab}



\subsubsection{Alternatively use projective integration}
\begin{figure}
\centering \caption{\label{fig:BurgersU}macroscale
space-time field \(u(x,t)\) in a basic projective
integration of the patch scheme applied to the microscale
Burgers' map.}
\includegraphics[scale=0.9]{BurgersU}
\end{figure}%
Around the microscale burst \verb|burgerBurst()|, wrap the
projective integration function \verb|PIRK2()| of
\cref{sec:PIRK2}. \cref{fig:BurgersU} shows the
macroscale prediction of the patch centre values on
macroscale time-steps.

This second part of the script implements the following design.
\begin{enumerate} \def\itemsep{-1.5ex}
\item configPatches1 (done in first part)
\item PIRK2 \into burgerBurst \into patchSmooth1 \into burgersMap
\item process results
\end{enumerate}


Mark that edge-values of patches are not to be used in the
projective extrapolation by setting initial values to \nan.
\begin{matlab}
%}
u0([1 end],:) = nan;
%{
\end{matlab}
Set the desired macroscale time-steps, and microscale
burst length over the time domain.  Then projectively
integrate in time using \verb|PIRK2()| which is (roughly)
second-order accurate in the macroscale time-step.
\begin{matlab}
%}
ts = linspace(0,0.5,11);
bT = 3*(ratio*Len/nPatch/(nSubP/2-1))^2
addpath('../ProjInt')
[us,tss,uss] = PIRK2(@burgerBurst,ts,u0(:),bT);
%{
\end{matlab}
Plot and save the macroscale predictions of the mid-patch
values to give the macroscale mesh-surface of
\cref{fig:BurgersU} that shows a progressing wave
solution.
\begin{matlab}
%}
figure(2),clf
midP = (nSubP+1)/2;
mesh(ts,xs(midP,:),us(:,midP:nSubP:end)')
xlabel('time t'), ylabel('space x'), zlabel('u(x,t)')
view(120,50)
set(gcf,'paperposition',[0 0 14 10])
print('-depsc2','BurgersU')
%{
\end{matlab}
Then plot and save the microscale mesh of the microscale
bursts shown in \cref{fig:BurgersMicro} (a stereo pair). 
The details of the fine microscale mesh are almost
invisible.
\begin{figure}
\centering \caption{\label{fig:BurgersMicro}the field
\(u(x,t)\) during each of the microscale bursts used in the
projective integration.  View this stereo pair cross-eyed.}
\includegraphics[scale=0.85]{BurgersMicro}
\end{figure}
\begin{matlab}
%}
figure(3),clf
for k = 1:2, subplot(2,2,k)
  mesh(tss,xs(:),uss')
  ylabel('x'),xlabel('t'),zlabel('u(x,t)')
  axis tight, view(126-4*k,50)
end
set(gcf,'paperposition',[0 0 17 12])
print('-depsc2','BurgersMicro')
%{
\end{matlab}






\subsection{\texttt{burgersMap()}: discretise the PDE microscale}
\label{sec:burgersMap}
This function codes the microscale Euler integration map of
the lattice differential equations inside the patches.  Only
the patch-interior values mapped (\verb|patchSmooth1()|
overrides the edge-values anyway).
\begin{matlab}
%}
function u = burgersMap(t,u,x)
  dx = diff(x(2:3));   
  dt = dx^2/2;
  i = 2:size(u,1)-1;
  u(i,:) = u(i,:) +dt*( diff(u,2)/dx^2 ...
     -20*u(i,:).*(u(i+1,:)-u(i-1,:))/(2*dx) );
end
%{
\end{matlab}



\subsection{\texttt{burgerBurst()}: code a burst of the patch map}
\label{sec:burgerBurst}
\begin{matlab}
%}
function [ts, us] = burgerBurst(ti, ui, bT) 
%{
\end{matlab}
First find and set the number of microscale time-steps.
\begin{matlab}
%}
  global patches
  dt = diff(patches.x(2:3))^2/2;
  ndt = ceil(bT/dt -0.2);
  ts = ti+(0:ndt)'*dt;
%{
\end{matlab}
Use \verb|patchSmooth1()| (\cref{sec:patchSmooth1}) to apply
the microscale map over all time-steps in the burst. The
\verb|patchSmooth1()| interface provides the interpolated
edge-values of each patch.  Store the results in rows to be
consistent with \ode\ and projective integrators.
\begin{matlab}
%}
  us = nan(ndt+1,numel(ui)); 
  us(1,:) = reshape(ui,1,[]);
  for j = 1:ndt
    ui = patchSmooth1(ts(j),ui);
    us(j+1,:) = reshape(ui,1,[]);
  end
%{
\end{matlab}
Linearly interpolate (extrapolate) to get the field values
at the precise final time of the burst.  Then return.
\begin{matlab}
%}
  ts(ndt+1) = ti+bT;
  us(ndt+1,:) = us(ndt,:) ...
    + diff(ts(ndt:ndt+1))/dt*diff(us(ndt:ndt+1,:));
end
%{
\end{matlab}
Fin.
%}
