% Simulate heterogeneous diffusion in 1D on patches as an
% example application of patches in space.
% AJR, Nov 2017 -- Oct 2018
%!TEX root = ../Doc/equationFreeDoc.tex
%{
\subsection[\texttt{HomogenisationExample}: simulate heterogeneous diffusion in 1D \ldots]{\texttt{HomogenisationExample}: simulate heterogeneous diffusion in 1D on patches}
\label{sec:HomogenisationExample}
\localtableofcontents

\cref{fig:ps1HomogenisationCtsU} shows an example simulation
in time generated by the patch scheme function applied to
heterogeneous diffusion. That such simulations of
heterogeneous diffusion makes valid predictions was
established by \cite{Bunder2013b} who proved that the scheme
is accurate when the number of points in a patch is one more
than an even multiple of the microscale periodicity.

The first part of the script implements the following gap-tooth scheme
(arrows indicate function recursion).
\begin{enumerate}\def\itemsep{-1.5ex}
\item configPatches1 
\item ode15s \into patchSmooth1 \into heteroDiff
\item process results
\end{enumerate}

\begin{body}
\begin{figure}
\centering \caption{\label{fig:ps1HomogenisationCtsU}the
diffusing field~\(u(x,t)\) in the patch (gap-tooth) scheme
applied to microscale heterogeneous diffusion.}
\includegraphics[scale=0.85]{../Patch/ps1HomogenisationCtsU}
\end{figure}%
Consider a lattice of values~\(u_i(t)\), with lattice
spacing~\(dx\), and governed by the heterogeneous diffusion 
\begin{equation}
\dot u_i=[c_{i-1/2}(u_{i-1}-u_i)+c_{i+1/2}(u_{i+1}-u_i)]/dx^2.
\label{eq:HomogenisationExample}
\end{equation}
In this 1D space, the macroscale, homogenised, effective
diffusion should be the harmonic mean of these coefficients.


\subsubsection{Script to simulate via stiff or projective integration}
Set the desired microscale periodicity, and microscale
diffusion coefficients (with subscripts shifted by a half).
\begin{matlab}
%}
clear all
mPeriod = 3
cDiff = exp(randn(mPeriod,1))
cHomo = 1/mean(1./cDiff)
%{
\end{matlab}

Establish global data struct for heterogeneous diffusion
solved on \(2\pi\)-periodic domain, with eight patches, each
patch of half-size~\(0.2\), and the number of points in a
patch being one more than an even multiple of the microscale
periodicity (which \cite{Bunder2013b} showed is accurate).
Quadratic (fourth-order) interpolation provides values for
the inter-patch coupling conditions.
\begin{matlab}
%}
global patches
nPatch = 9
ratio = 0.2
nSubP = 2*mPeriod+1
Len = 2*pi;
configPatches1(@heteroDiff,[0 Len],nan,nPatch,4,ratio,nSubP);
%{
\end{matlab}
A user can add information to the global data
struct~\verb|patches| in order to communicate to the time
derivative function. Here include the diffusivity
coefficients, replicated to fill up a patch.
\begin{matlab}
%}
patches.c = repmat(cDiff,(nSubP-1)/mPeriod,1);
%{
\end{matlab}

\paragraph{Conventional integration in time}
Set an initial condition, and here integrate forward in time
using a standard method for stiff systems---because of the
simplicity of linear problems this method works quite
efficiently here.  Integrate the interface
\verb|patchSmooth1| (\cref{sec:patchSmooth1}) to the
microscale differential equations.
\begin{matlab}
%}
%u0 = sin(patches.x)+0.2*randn(nSubP,nPatch);
u0 = exp(-2*(patches.x-Len/2).^2).*(1+0.1*rand(nSubP,nPatch));
[ts,ucts] = ode15s(@patchSmooth1, [0 2/cHomo], u0(:));
%{
\end{matlab}
Plot the simulation in \cref{fig:ps1HomogenisationCtsU}.
\begin{matlab}
%}
figure(1),clf
xs = patches.x;  xs([1 end],:) = nan;
mesh(ts,xs(:),ucts'),  view(60,40)
xlabel('time t'), ylabel('space x'), zlabel('u(x,t)')
set(gcf,'paperposition',[0 0 14 10])
print('-depsc2','ps1HomogenisationCtsU')
%{
\end{matlab}

\paragraph{Use projective integration in time}
\begin{figure}
\centering \caption{\label{fig:ps1HomogenisationU}field
\(u(x,t)\) shows basic projective integration of patches of
heterogeneous diffusion: different colours correspond to 
the times in the legend.}
\includegraphics[scale=0.85]{../Patch/ps1HomogenisationU}
\end{figure}%
Now take \verb|patchSmooth1|, the interface to the time
derivatives, and wrap around it the projective integration
\verb|PIRK2| (\cref{sec:PIRK2}), of bursts of simulation
from \verb|heteroBurst| (\cref{sec:heteroBurst}), as
illustrated by \cref{fig:ps1HomogenisationU}.

This second part of the script implements the following design, where the micro-integrator could be, for example, \verb|ode23| or \verb|rk2int|.
\begin{enumerate} \def\itemsep{-1.5ex}
\item configPatches1 (done in first part)
\item PIRK2 \into heteroBurst \into micro-integrator \into patchSmooth1 \into heteroDiff
\item process results
\end{enumerate}

Mark that edge of patches are not to be used in the
projective extrapolation by setting initial values to \nan.
\begin{matlab}
%}
u0([1 end],:) = nan;
%{
\end{matlab}
Set the desired macro- and micro-scale time-steps over the
time domain: the macroscale step is in proportion to the
effective mean diffusion time on the macroscale; the burst
time is proportional to the intra-patch effective diffusion
time; and lastly, the microscale time-step is proportional
to the diffusion time between adjacent points in the
microscale lattice.
\begin{matlab}
%}
ts = linspace(0,2/cHomo,7)
bT = 3*( ratio*Len/nPatch )^2/cHomo
addpath('../ProjInt','../RKint')
[us,tss,uss] = PIRK2(@heteroBurst, bT, ts, u0(:));
%{
\end{matlab}
Plot the macroscale predictions to draw
\cref{fig:ps1HomogenisationU}.
\begin{matlab}
%}
figure(2),clf
plot(xs(:),us','.')
ylabel('u(x,t)'), xlabel('space x')
legend(num2str(ts',3))
set(gcf,'paperposition',[0 0 14 10])
print('-depsc2','ps1HomogenisationU')
%{
\end{matlab}
Also plot a surface detailing the microscale bursts as shown
in \cref{fig:ps1HomogenisationMicro}.
\begin{figure}
\centering \caption{\label{fig:ps1HomogenisationMicro}stereo
pair of the field~\(u(x,t)\) during each of the microscale
bursts used in the projective integration.}
\includegraphics[scale=0.85]{../Patch/ps1HomogenisationMicro}
\end{figure}
\begin{matlab}
%}
figure(3),clf
for k = 1:2, subplot(2,2,k)
  surf(tss,xs(:),uss',  'EdgeColor','none')
  ylabel('x'), xlabel('t'), zlabel('u(x,t)')
  axis tight, view(126-4*k,45)
end
set(gcf,'paperposition',[0 0 17 12])
print('-depsc2','ps1HomogenisationMicro')
%{
\end{matlab}
End of the script.



\subsubsection{\texttt{heteroDiff()}: heterogeneous diffusion}
\label{sec:heteroDiff}
This function codes the lattice heterogeneous diffusion
inside the patches.  For 2D input arrays~\verb|u|
and~\verb|x| (via edge-value interpolation of
\verb|patchSmooth1|, \cref{sec:patchSmooth1}), computes the
time derivative~\cref{eq:HomogenisationExample} at each
point in the interior of a patch, output in~\verb|ut|.  The
column vector (or possibly array) of diffusion
coefficients~\(c_i\) have previously been stored in
struct~\verb|patches|.\footnote{Use \texttt{bsxfun()} as
pre-2017 Matlab versions may not support auto-replication.}
\begin{matlab}
%}
function ut = heteroDiff(t,u,x)
  global patches
  dx = diff(x(2:3)); % space step
  i = 2:size(u,1)-1; % interior points in a patch
  ut = nan(size(u)); % preallocate output array
  ut(i,:) = diff(bsxfun(@times,patches.c,diff(u.^2)))/dx^2 ;
end% function
%{
\end{matlab}


\subsubsection{\texttt{heteroBurst()}: a burst of heterogeneous diffusion}
\label{sec:heteroBurst}
This code integrates in time the derivatives computed by
\verb|heteroDiff| from within the patch coupling of
\verb|patchSmooth1|.  Try three possibilities:
\begin{itemize}
\item \verb|ode23| generates `noise' that is unsightly at
best and may be ruinous;
\item \verb|ode15s| does not cater for the \nan{}s in some
components of~\verb|u|;
\item \verb|rk2int| simple specified step integrator behaves
consistently, and so appears best.
\end{itemize}

\begin{matlab}
%}
function [ts, ucts] = heteroBurst(ti, ui, bT) 
  switch 'rk2'
  case '23',  [ts,ucts] = ode23 (@patchSmooth1,[ti ti+bT],ui(:));
  case '15s', [ts,ucts] = ode15s(@patchSmooth1,[ti ti+bT],ui(:));
  case 'rk2', ts = linspace(ti,ti+bT,200)';
              ucts = rk2int(@patchSmooth1,ts,ui(:));
  end
end
%{
\end{matlab}
Fin.
\end{body}
%}
