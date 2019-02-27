% Simulate heterogeneous diffusion in 1D on patches as an
% example application of patches in space.
% AJR, Nov 2017 -- Feb 2019
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\section[\texttt{HomogenisationExample}: simulate heterogeneous diffusion in 1D \ldots]{\texttt{HomogenisationExample}: simulate heterogeneous diffusion in 1D on patches}
\label{sec:HomogenisationExample}
\localtableofcontents

\Cref{fig:HomogenisationCtsU,fig:HomogenisationCtsUEnsAve} 
show example simulations in time generated by the patch
scheme function applied to heterogeneous diffusion. That
such simulations of heterogeneous diffusion makes valid
predictions was established by \cite{Bunder2013b} who proved
that the scheme is accurate when the number of points in a
patch minus the number of points in the core is an even
multiple of the microscale periodicity. We present two
different methods of obtaining a macroscale solution. One
method uses the given heterogeneous diffusion, which
produces a solution which has microscale roughness
(\cref{fig:HomogenisationCtsU}). The other method constructs
an ensemble of heterogeneous diffusion and produces an
ensemble average solution which has a smooth microscale
(\cref{fig:HomogenisationCtsUEnsAve}). 

The first part of the script implements the following
gap-tooth scheme (left-right arrows denote function
recursion).
\begin{enumerate}\def\itemsep{-1.5ex}
\item configPatches1 
\item ode15s \into patchSmooth1 \into heteroDiff
\item process results
\end{enumerate}
\begin{figure}
\centering \caption{\label{fig:HomogenisationCtsU}the
diffusing field~\(u(x,t)\) in the patch (gap-tooth) scheme
applied to microscale heterogeneous diffusion with no
ensemble average. The heterogeneous diffusion results in a
smilarly heterogeneous  field solution.}
\includegraphics[scale=0.9]{HomogenisationCtsU}
\end{figure}%
\begin{figure}
\centering \caption{\label{fig:HomogenisationCtsUEnsAve}the
diffusing field~\(u(x,t)\) in the patch (gap-tooth) scheme
applied to microscale heterogeneous diffusion with an
ensemble average. The ensemble average smooths out the
heterogeneous diffusion.}
\includegraphics[scale=0.9]{HomogenisationCtsUEnsAve}
\end{figure}%

Consider a lattice of values~\(u_i(t)\), with lattice
spacing~\(dx\), and governed by the heterogeneous diffusion 
\begin{equation}
\dot u_i=[c_{i-1/2}(u_{i-1}-u_i)+c_{i+1/2}(u_{i+1}-u_i)]/dx^2.
\label{eq:HomogenisationExample}
\end{equation}
In this 1D space, the macroscale, homogenised, effective
diffusion should be the harmonic mean of these coefficients.


\subsection{Script to simulate via stiff or projective integration}
Set the desired microscale periodicity, and microscale
diffusion coefficients (with subscripts shifted by a half).
\begin{matlab}
%}
clear all
mPeriod = 4
rng('default'); rng(1);
cDiff = exp(4*rand(mPeriod,1))
cHomo = 1/mean(1./cDiff)
%{
\end{matlab}

Establish global data struct~\verb|patches| for
heterogeneous diffusion solved on \(2\pi\)-periodic domain,
with nine patches, each patch of half-size~\(0.2\). A user
can add information to~\verb|patches| in order to
communicate to the time derivative function. Quadratic
(fourth-order) interpolation  \(\verb|ordCC|=4\) provides
values for the inter-patch coupling conditions. The odd
integer \(\verb|patches.nCore|=3\) defines the size of the
patch core (this must be larger than zero and less than
\verb|nSubP|), where a core of size zero indicates that the
value in the centre of the patch gives the macroscale. The
introduction of a finite width core requires a redefinition
of the half-patch ratio, as described by \cite{Bunder2013b}.
The Boolean \verb|patches.EnsAve| determines whether or not we
apply ensemble averaging of diffusivity configurations. We
evaluate the patch coupling by interpolating the core.
\begin{matlab}
%}
global patches
nPatch = 9
ratio = 0.2
nSubP = 11
Len = 2*pi;
ordCC=4;
patches.nCore=3; 
patches.ratio = ratio*(nSubP - patches.nCore)/(nSubP - 1);
configPatches1(@heteroDiff,[0 Len],nan,nPatch, ...
 ordCC,patches.ratio,nSubP);
patches.EnsAve = 1;
%{
\end{matlab}

A \((\verb|nSubP-1)|\times \verb|nPatch|\) matrix defines
the diffusivity coefficients within each patch. In the case
of ensemble averaging, \verb|nVars| becomes the size of the
ensemble (for the case of no ensemble averaging \verb|nVars|
is the number of different field variables, which in this
example is \(\verb|nVars|=1\)) and we use the ensemble
described by \cite{Bunder2013b} which includes all reflected
and translated configurations of \verb|patches.cDiff|. With
ensemble averaging we must increase the size of the
diffusivity matrix to \((\verb|nSubP-1)|\times
\verb|nPatch|\times \verb|nVars|\).
\begin{matlab}
%}
patches.cDiff = cDiff((mod(round(patches.x(1:(end-1),:) ...
  /(patches.x(2)-patches.x(1))-0.5),mPeriod)+1));
if patches.EnsAve    
  if mPeriod>2
    nVars=2*mPeriod;
  else
    nVars=mPeriod;
  end
  patches.cDiff=repmat(patches.cDiff,[1,1,nVars]);    
  for sx=2:mPeriod
    patches.cDiff(:,:,sx)=circshift( ...
      patches.cDiff(:,:,sx-1),[sx-1,0]);
   end;
   if nVars>2
     patches.cDiff(:,:,(mPeriod+1):end)=flipud( ...
       patches.cDiff(:,:,1:mPeriod)); 
   end;
end
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
u0 = sin(patches.x)+0.2*randn(nSubP,nPatch);
%u0 = exp(-2*(patches.x-Len/2).^2).*(1+0.1*rand(nSubP,nPatch));
if patches.EnsAve
  u0 = repmat(u0,[1,1,nVars]);
end
[ts,ucts] = ode15s(@patchSmooth1, [0 2/cHomo], u0(:));
ucts=reshape(ucts,length(ts),length(patches.x(:)),[]);
%{
\end{matlab}

Plot the simulation in \cref{fig:HomogenisationCtsU} (with
no ensemble average) or \cref{fig:HomogenisationCtsUEnsAve}
(with an ensemble average). If we have calculated an
ensemble of field solutions, then we must first take the
ensemble average. 
\begin{matlab}
%}
if patches.EnsAve % calculate the ensemble average
  uctsAve=mean(ucts,3);
else
  uctsAve=ucts;
end
figure(1),clf
xs = patches.x;  xs([1 end],:) = nan;
mesh(ts,xs(:),uctsAve'),  view(60,40)
xlabel('time t'), ylabel('space x'), zlabel('u(x,t)')
set(gcf,'PaperUnits','centimeters');
set(gcf,'PaperPosition',[0 0 14 10]);
if patches.EnsAve
  print('-depsc2','HomogenisationCtsUEnsAve')
else
  print('-depsc2','HomogenisationCtsU')
end
%{
\end{matlab}

\paragraph{Use projective integration in time}
\begin{figure}
\centering \caption{\label{fig:HomogenisationU}field
\(u(x,t)\) shows basic projective integration of patches of
heterogeneous diffusion with no ensemble average: different
colours correspond to the times in the legend. This field
solution displays some fine scale heterogeneity due to the
heterogeneous diffusion.}
\includegraphics[scale=0.9]{HomogenisationU}
\end{figure}%
\begin{figure}
\centering \caption{\label{fig:HomogenisationUEnsAve}field
\(u(x,t)\) shows basic projective integration of patches of
heterogeneous diffusion with ensemble average: different
colours correspond to the times in the legend. Once
transients have decayed, this field solution is smooth due
to the ensemble average.}
\includegraphics[scale=0.9]{HomogenisationUEnsAve}
\end{figure}%

Now take \verb|patchSmooth1|, the interface to the time
derivatives, and wrap around it the projective integration
\verb|PIRK2| (\cref{sec:PIRK2}), of bursts of simulation
from \verb|heteroBurst| (\cref{sec:heteroBurst}), as
illustrated by
\Cref{fig:HomogenisationU,fig:HomogenisationUEnsAve}.

This second part of the script implements the following
design, where the micro-integrator could be, for example,
\verb|ode45| or \verb|rk2int|.
\begin{enumerate} \def\itemsep{-1.5ex}
\item configPatches1 (done in first part)
\item PIRK2 \into heteroBurst \into micro-integrator \into
patchSmooth1 \into heteroDiff
\item process results
\end{enumerate}
Mark that edge of patches are not to be used in the
projective extrapolation by setting initial values to \nan.
\begin{matlab}
%}
u0([1 end],:) = nan;
%{
\end{matlab}
Set the desired macro- and microscale time-steps over the
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
addpath('../ProjInt','../SandpitPlay/RKint')
[us,tss,uss] = PIRK2(@heteroBurst, ts, u0(:), bT);
%{
\end{matlab}
Plot the macroscale predictions to draw
\cref{fig:HomogenisationU} or
\cref{fig:HomogenisationUEnsAve}. If we have calculated an
ensemble of field solutions, then we must first take the
ensemble average. 
\begin{matlab}
%}
if patches.EnsAve % calculate the ensemble average
  usAve=mean(reshape(us,size(us,1),length(xs(:)),nVars),3); 
  ussAve=mean(reshape(uss,length(tss),length(xs(:)),nVars),3);
else
  usAve=us;
  ussAve=uss;
end
figure(2),clf
plot(xs(:),usAve','.')
ylabel('u(x,t)'), xlabel('space x')
legend(num2str(ts',3))
set(gcf,'PaperUnits','centimeters');
set(gcf,'PaperPosition',[0 0 14 10]);
if patches.EnsAve
  print('-depsc2','HomogenisationUEnsAve')
else
  print('-depsc2','HomogenisationU')
end
%{
\end{matlab}
Also plot a surface detailing the microscale bursts as shown
in \cref{fig:HomogenisationMicro} or
\cref{fig:HomogenisationMicroEnsAve}.
\begin{figure}
\centering \caption{\label{fig:HomogenisationMicro}stereo
pair of the field~\(u(x,t)\) during each of the microscale
bursts used in the projective integration with no ensemble
averaging.}
\includegraphics[scale=0.9]{HomogenisationMicro}
\end{figure}
\begin{figure}
\centering
\caption{\label{fig:HomogenisationMicroEnsAve}stereo pair of
the field~\(u(x,t)\) during each of the microscale bursts
used in the projective integration with ensemble averaging.}
\includegraphics[scale=0.9]{HomogenisationMicro}
\end{figure}
\begin{matlab}
%}
figure(3),clf
for k = 1:2, subplot(1,2,k)
  surf(tss,xs(:),ussAve',  'EdgeColor','none')
  ylabel('x'), xlabel('t'), zlabel('u(x,t)')
  axis tight, view(126-4*k,45)
end
set(gcf,'PaperUnits','centimeters');
set(gcf,'PaperPosition',[0 0 14 6]);
if patches.EnsAve
  print('-depsc2','HomogenisationMicroEnsAve')
else
  print('-depsc2','HomogenisationMicro')
end
%{
\end{matlab}
End of the script.


\subsection{\texttt{heteroDiff()}: heterogeneous diffusion}
\label{sec:heteroDiff}
This function codes the lattice heterogeneous diffusion
inside the patches.  For 2D input arrays~\verb|u|
and~\verb|x| (via edge-value interpolation of
\verb|patchSmooth1|, \cref{sec:patchSmooth1}), computes the
time derivative~\cref{eq:HomogenisationExample} at each
point in the interior of a patch, output in~\verb|ut|.  The
column vector (or possibly array) of diffusion
coefficients~\(c_i\) have previously been stored in
struct~\verb|patches|.
\begin{matlab}
%}
function ut = heteroDiff(t,u,x)
  global patches
  dx = diff(x(2:3)); % space step
  i = 2:size(u,1)-1; % interior points in a patch
  ut = nan(size(u)); % preallocate output array
  ut(i,:,:) = diff(patches.cDiff.*diff(u))/dx^2; %- abs(u(i,:,:)).*u(i,:,:).^2;
end% function
%{
\end{matlab}



\subsection{\texttt{heteroBurst()}: a burst of heterogeneous diffusion}
\label{sec:heteroBurst}
This code integrates in time the derivatives computed by
\verb|heteroDiff| from within the patch coupling of
\verb|patchSmooth1|.  Try four possibilities:
\begin{itemize}
\item \verb|ode23| generates `noise' that is unsightly at
best and may be ruinous;
\item \verb|ode45| is similar to \verb|ode23|, but with reduced noise;
\item \verb|ode15s| does not cater for the \nan{}s in some
components of~\verb|u|;
\item \verb|rk2int| simple specified step integrator, but may require 
inefficiently small time-steps.
\end{itemize}
\begin{matlab}
%}
function [ts, ucts] = heteroBurst(ti, ui, bT) 
  switch '45'
  case '23',  [ts,ucts] = ode23(@patchSmooth1,[ti ti+bT],ui(:));
  case '45',  [ts,ucts] = ode45(@patchSmooth1,[ti ti+bT],ui(:));
  case '15s', [ts,ucts] = ode15s(@patchSmooth1,[ti ti+bT],ui(:));
  case 'rk2', ts = linspace(ti,ti+bT,200)';
              ucts = rk2int(@patchSmooth1,ts,ui(:));
  end
end
%{
\end{matlab}
Fin.
%}
