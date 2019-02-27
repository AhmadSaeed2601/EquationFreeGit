% Simulate water waves on patches as an example of wave
% systems in the form h_t=u_x+... and u_u=h_x+...
% AJR, Nov 2017 -- Oct 2018
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\section{\texttt{waterWaveExample}: simulate a water wave PDE on patches}
\label{sec:waterWaveExample}
\localtableofcontents

\cref{fig:ps1WaveCtsUH} shows an example simulation in time
generated by the patch scheme function applied to an ideal
wave \pde\ \cite[]{Cao2013}. The inter-patch coupling is
realised by spectral interpolation of the mid-patch values
to the patch edges.

This approach, based upon the differential equations coded
in \cref{sec:idealWavePDE}, may be adapted by a user to a
wide variety of 1D wave and wave-like systems. For example,
the differential equations of \cref{sec:waterWavePDE}
describes the nonlinear microscale simulator of the
nonlinear shallow water wave \pde\ derived from the
Smagorinski model of turbulent flow \cite[]{Cao2012,
Cao2014b}.

\begin{devMan}
\begin{figure}
\centering \caption{\label{fig:ps1WaveCtsUH}water
depth~\(h(x,t)\) (above) and velocity field~\(u(x,t)\)
(below) of the gap-tooth scheme applied to the ideal wave
\pde~\cref{eq:genwaveqn}, linearised. The microscale random
component to the initial condition has long lasting effects
on the simulation---but the macroscale wave still
propagates.}
\includegraphics[scale=0.85]{ps1WaveCtsUH}
\end{figure}%
Often, wave-like systems are written in terms of two
conjugate variables, for example, position and momentum
density, electric and magnetic fields, and water
depth~\(h(x,t)\) and mean longitudinal velocity~\(u(x,t)\)
as herein. The approach developed in this section applies to
any wave-like system in the form
\begin{equation}
\D th=-c_1\D xu+f_1[h,u]
\quad\text{and}\quad
\D tu=-c_2\D xh+f_2[h,u],
\label{eq:genwaveqn}
\end{equation}
where the brackets indicate that the nonlinear
functions~\(f_\ell\) may involve various spatial derivatives
of the fields~\(h(x,t)\) and~\(u(x,t)\). For example,
\cref{sec:waterWavePDE} encodes a nonlinear Smagorinski
model of turbulent shallow water \cite[e.g.]{Cao2012,
Cao2014b} along an inclined flat bed: let $x$~measure
position along the bed and in terms of fluid depth~$h(x,t)$
and depth-averaged longitudinal velocity~$u(x,t)$ the model
\pde{}s are
\begin{subequations}\label{eqs:patch:N}%
\begin{align}
\D th&=-\D x{(hu)}\,,\label{patch:Nh}
\\
\D tu&=0.985\left(\tan\theta-\D xh\right)
-0.003\frac{u|u|}{h} -1.045u\D xu +0.26h|u|\DD xu\,,
\label{patch:Nu}
\end{align}
\end{subequations}
where~$\tan\theta$ is the slope of the bed.
Equation~\cref{patch:Nh} represents conservation of the
fluid. The momentum \pde~\cref{patch:Nu} represents  the
effects of turbulent bed drag~$u|u|/h$, self-advection~$u\D
xu$, nonlinear turbulent dispersion~$h|u|\DD xu$, and
gravitational hydrostatic forcing~$(\tan\theta-\D xh)$.
\cref{fig:ps1WaterWaveCtsUH} shows one simulation of this
system---for the same initial condition as
\cref{fig:ps1WaveCtsUH}.

\begin{figure}
\centering \caption{\label{fig:ps1WaterWaveCtsUH}water
depth~\(h(x,t)\) (above) and velocity field~\(u(x,t)\)
(below) of the gap-tooth scheme applied to the Smagorinski
shallow water wave \pde{}s~\cref{eqs:patch:N}. The
microscale random initial component decays where the water
speed is non-zero due to `turbulent' dissipation.}
\includegraphics[scale=0.85]{ps1WaterWaveCtsUH}
\end{figure}%


For such wave systems, let's implement a staggered
microscale grid and staggered macroscale patches as
introduced by \cite{Cao2014a} in their Figures~3 and~4,
respectively.




\subsection{Script code to simulate wave systems}
\label{sec:sc2waves}

This script implements the following gap-tooth scheme
(left-right arrows denote function recursion).
\begin{enumerate}\def\itemsep{-1.5ex}
\item configPatches1, and add micro-information 
\item ode15s \into patchSmooth1 \into idealWavePDE
\item process results
\item ode15s \into patchSmooth1 \into waterWavePDE
\item process results
\end{enumerate}
Establish the global data struct~\verb|paches| for the
\pde{}s~\cref{eq:genwaveqn} (linearised) solved on
\(2\pi\)-periodic domain, with eight patches, each patch of
half-size ratio~\(0.2\), with eleven points within each
patch, and spectral interpolation~(\(-1\)) to provide
edge-values of the inter-patch coupling conditions.
\begin{matlab}
%}
clear all
global patches
nPatch = 8
ratio = 0.2
nSubP = 11 %of the form 4*n-1
Len = 2*pi;
configPatches1(@idealWavePDE,[0 Len],nan,nPatch,-1,ratio,nSubP);
%{
\end{matlab}

Identify which microscale grid points are \(h\)~or~\(u\)
values on the staggered micro-grid. Also store the
information in the struct~\verb|patches| for use by the time
derivative function.
\begin{matlab}
%}
uPts = mod( bsxfun(@plus,(1:nSubP)',(1:nPatch)) ,2);
hPts = find(1-uPts);
uPts = find(uPts);
patches.hPts = hPts; patches.uPts = uPts;
%{
\end{matlab}

Set an initial condition of a progressive wave, and check
evaluation of the time derivative. The capital
letter~\verb|U| denotes an array of values merged from
both~\(u\) and~\(h\) fields on the staggered grids (possibly
with some optional microscale wave noise).
\begin{matlab}
%}
U0 = nan(nSubP,nPatch);
U0(hPts) = 1+0.5*sin(patches.x(hPts));
U0(uPts) = 0+0.5*sin(patches.x(uPts));
U0 = U0+0.02*randn(nSubP,nPatch);
%{
\end{matlab}

\paragraph{Conventional integration in time}
Integrate in time using standard \script\ stiff integrators.
Here do the two cases of the ideal wave and the water wave
equations in the one loop.
\begin{matlab}
%}
for k = 1:2
%{
\end{matlab}
When using \verb|ode15s| we subsample the results because
sub-grid scale waves do not dissipate and so the integrator
takes very small time-steps for all time.
\begin{matlab}
%}
  [ts,Ucts] = ode15s(@patchSmooth1,[0 4],U0(:));
  ts = ts(1:5:end);
  Ucts = Ucts(1:5:end,:);
%{
\end{matlab}
Plot the simulation.
\begin{matlab}
%}
  figure(k),clf
  xs = patches.x;  xs([1 end],:) = nan;
  mesh(ts,xs(hPts),Ucts(:,hPts)'),hold on
  mesh(ts,xs(uPts),Ucts(:,uPts)'),hold off
  xlabel('time t'), ylabel('space x'), zlabel('u(x,t) and h(x,t)')
  axis tight, view(70,45)
%{
\end{matlab}
Save the plot to file.
\begin{matlab}
%}
  set(gcf,'paperposition',[0 0 14 10])
  if k==1, print('-depsc2','ps1WaveCtsUH')
  else print('-depsc2','ps1WaterWaveCtsUH')
  end
%{
\end{matlab}

For the second time through the loop, change to the
Smagorinski turbulence model~\cref{eqs:patch:N} of shallow
water flow, keeping other parameters and the initial
condition the same. 
\begin{matlab}
%}
  patches.fun = @waterWavePDE;
end
%{
\end{matlab}

\paragraph{Use projective integration}
As yet a simple implementation appears to fail, so it needs
more exploration and thought.
%\begin{figure}
%\centering
%\caption{\label{fig:ps1WaterWaveU}basic projective integration of the patch scheme function applied to a water Wave' \pde.}
%%\includegraphics[scale=0.85]{ps1WaterWaveU}
%\end{figure}%
%Now wrap around the patch time derivative function, \verb|patchSmooth1|, the projective integration function for patch simulations as illustrated by \cref{fig:ps1WaterWaveU}.
%
%Mark that edge of patches are not to be used in the projective extrapolation by setting initial values to \nan.
%\begin{matlab}
%%}
%U0([1 end],:) = nan;
%%{
%\end{matlab}
%Set the desired macro- and microscale time-steps over the time domain.
%\begin{matlab}
%%}
%ts = linspace(0,1,6)
%dt = 0.1*(ratio)^2;
%%{
%\end{matlab}
%
%Projectively integrate in time with: 
%\textsc{dmd} projection of rank \(\verb|nPatch|+1\); 
%guessed microscale time-step~\verb|dt|; and 
%guessed numbers of transient and slow steps.
%\begin{matlab}
%%}
%addpath('../ProjInt')
%[Us,Uss,tss] = projInt1(@patchSmooth1,U0(:),ts ...
%    ,nPatch+1,dt,[10 nPatch*2]);
%%{
%\end{matlab}
%Plot the macroscale predictions to draw \cref{fig:ps1WaterWaveU}, in groups of five in a plot.
%\begin{matlab}
%%}
%figure(3),clf
%k = length(ts); ls = nan(5,ceil(k/5)); ls(1:k) = 1:k;
%for k = 1:size(ls,2)
%  subplot(size(ls,2),1,k)
%  plot(xs(:),Us(:,ls(~isnan(ls(:,k)),k)),'.')
%  ylabel('u(x,t) and h(x,t)')
%  legend(num2str(ts(ls(~isnan(ls(:,k)),k))'))
%end
%xlabel('space x')
%%print('-depsc2','ps1WaterWaveU')
%%{
%\end{matlab}
%Also plot a surface of the microscale bursts as shown in \cref{fig:ps1WaterWaveMicro}.
%\begin{figure}
%\centering
%\caption{\label{fig:ps1WaterWaveMicro}stereo pair of the field \(u(x,t)\) during each of the microscale bursts used in the projective integration.}
%%\includegraphics[scale=0.85]{ps1WaterWaveMicro}
%\end{figure}
%\begin{matlab}
%%}
%tss(end) = nan; %omit end time-point
%figure(4),clf
%for k = 1:2, subplot(2,2,k)
%  surf(tss,xs(patches.hPts),Uss(patches.hPts,:) ...
%  ,'EdgeColor','none'),hold on
%  surf(tss,xs(patches.uPts),Uss(patches.uPts,:) ...
%  ,'EdgeColor','none'),hold off
%%  surf(tss,xs(:),Uss,'EdgeColor','none')
%  ylabel('x'),xlabel('t'),zlabel('U(x,t) and H(x,t)')
%  axis tight, view(76-4*k,45)
%end
%%print('-depsc2','ps1WaterWaveMicro')
%%{
%\end{matlab}
End of the main script.




\subsection{\texttt{idealWavePDE()}: ideal wave PDE}
\label{sec:idealWavePDE}
This function codes the staggered lattice equation inside
the patches for the ideal wave \pde\ system \(h_t=-u_x\) and
\(u_t=-h_x\). Here code for a staggered microscale grid,
index~\(i\), of staggered macroscale patches, index~\(j\):
the array
\begin{equation*}
U_{ij}=\begin{cases} u_{ij}&i+j\text{ even},\\
h_{ij}& i+j\text{ odd}.
\end{cases}
\end{equation*}
The output~\verb|Ut| contains the merged time derivatives of
the two staggered fields. So set the micro-grid spacing and
reserve space for time derivatives.
\begin{matlab}
%}
function Ut = idealWavePDE(t,U,x)
  global patches
  dx = diff(x(2:3));
  Ut = nan(size(U));  ht = Ut;
%{
\end{matlab}
Compute the \pde\ derivatives at interior points of the patches.
\begin{matlab}
%}
  i = 2:size(U,1)-1;
%{
\end{matlab}
Here `wastefully' compute time derivatives for both \pde{}s
at all grid points---for `simplicity'---and then merges the
staggered results. Since \(\dot h_{ij} \approx -(u_{i+1,j}
-u_{i-1,j}) /(2\cdot dx) =-(U_{i+1,j} -U_{i-1,j}) /(2\cdot
dx)\) as adding\slash subtracting one from the index of a
\(h\)-value is the location of the neighbouring \(u\)-value
on the staggered micro-grid.
\begin{matlab}
%}
  ht(i,:) = -(U(i+1,:)-U(i-1,:))/(2*dx);
%{
\end{matlab}
Since \(\dot u_{ij} \approx -(h_{i+1,j} -h_{i-1,j}) /(2\cdot
dx) =-(U_{i+1,j} -U_{i-1,j}) /(2\cdot dx)\) as adding\slash
subtracting one from the index of a \(u\)-value is the
location of the neighbouring \(h\)-value on the staggered
micro-grid.
\begin{matlab}
%}
  Ut(i,:) = -(U(i+1,:)-U(i-1,:))/(2*dx);
%{
\end{matlab}
Then overwrite the unwanted~\(\dot u_{ij}\) with the
corresponding wanted~\(\dot h_{ij}\).
\begin{matlab}
%}
  Ut(patches.hPts) = ht(patches.hPts);
end
%{
\end{matlab}



\subsection{\texttt{waterWavePDE()}: water wave PDE}
\label{sec:waterWavePDE}
This function codes the staggered lattice equation inside
the patches for the nonlinear wave-like \pde\
system~\cref{eqs:patch:N}. Also, regularise the absolute
value appearing the the \pde{}s via the one-line
function~\verb|rabs()|.
\begin{matlab}
%}
function Ut = waterWavePDE(t,U,x)
  global patches
  rabs = @(u) sqrt(1e-4 + u.^2);
%{
\end{matlab}
As before, set the micro-grid spacing, reserve space for
time derivatives, and index the patch-interior points of the
micro-grid.
\begin{matlab}
%}
  dx = diff(x(2:3));
  Ut = nan(size(U));  ht = Ut;
  i = 2:size(U,1)-1;
%{
\end{matlab}
Need to estimate~\(h\) at all the \(u\)-points, so 
into~\verb|V| use averages, and linear extrapolation to
patch-edges.
\begin{matlab}
%}
  ii = i(2:end-1);
  V = Ut;
  V(ii,:) = (U(ii+1,:)+U(ii-1,:))/2;
  V(1:2,:) = 2*U(2:3,:)-V(3:4,:);
  V(end-1:end,:) = 2*U(end-2:end-1,:)-V(end-3:end-2,:);
%{
\end{matlab}
Then estimate \(\D x{(hu)}\) from~\(u\) and the
interpolated~\(h\) at the neighbouring micro-grid points.
\begin{matlab}
%}
  ht(i,:) = -(U(i+1,:).*V(i+1,:)-U(i-1,:).*V(i+1,:))/(2*dx);
%{
\end{matlab}
Correspondingly estimate the terms in the momentum \pde:
\(u\)-values in~\(\verb|U|_i\) and~\(\verb|V|_{i\pm1}\); and
\(h\)-values in~\(\verb|V|_i\) and~\(\verb|U|_{i\pm1}\).
\begin{matlab}
%}
  Ut(i,:) = -0.985*(U(i+1,:)-U(i-1,:))/(2*dx) ...
    -0.003*U(i,:).*rabs(U(i,:)./V(i,:)) ...
    -1.045*U(i,:).*(V(i+1,:)-V(i-1,:))/(2*dx) ...
    +0.26*rabs(V(i,:).*U(i,:)).*(V(i+1,:)-2*U(i,:)+V(i-1,:))/dx^2/2;
%{
\end{matlab}
where the mysterious division by two in the second
derivative is due to using the averaged values of~\(u\) in
the estimate:
\begin{eqnarray*}
u_{xx}&\approx&\frac1{4\delta^2}(u_{i-2}-2u_i+u_{i+2})
\\&=&\frac1{4\delta^2}(u_{i-2}+u_i-4u_i+u_i+u_{i+2})
\\&=&\frac1{2\delta^2}\left(\frac{u_{i-2}+u_i}2-2u_i+\frac{u_i+u_{i+2}}2\right)
\\&=&\frac1{2\delta^2}\left(\bar u_{i-1}-2u_i+\bar u_{i+1}\right).
\end{eqnarray*}
Then overwrite the unwanted~\(\dot u_{ij}\) with the
corresponding wanted~\(\dot h_{ij}\).
\begin{matlab}
%}
  Ut(patches.hPts) = ht(patches.hPts);
end
%{
\end{matlab}
Fin.
\end{devMan}
%}
