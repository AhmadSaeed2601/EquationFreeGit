%Simulate heterogeneous diffusion in 1D on patches as an
%example application of patches in space. Here the
%microscale is of known period so we interpolate
%next-to-edge values to get opposite edge values. Then
%explore the Jacobian and eigenvalues.  AJR, 27 Nov 2019
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\section{\texttt{homoDiffEdgy1}: computational homogenisation of a 1D diffusion by simulation on small patches}
\label{sec:homoDiffEdgy1}
%\localtableofcontents

\cref{fig:homoDiffEdgyU2} shows an example simulation in
time generated by the patch scheme applied to macroscale
diffusion propagation through a medium with microscale
heterogeneity. The inter-patch coupling is realised by
quartic interpolation of the patch's next-to-edge values to
the patch opposite edges. Such coupling preserves symmetry
in many systems, and quartic appears to be the lowest order
that generally gives good accuracy.
\begin{figure}
\centering \caption{\label{fig:homoDiffEdgyU2}diffusion
field~\(u(x,t)\) of the gap-tooth scheme applied to the
diffusion~\cref{eq:hetroDiff}. The microscale random
component to the initial condition, the sub-patch
fluctuations, decays, leaving the emergent macroscale
diffusion. This simulation uses nine patches of `large'
size ratio~\(0.25\) for visibility.}
\includegraphics[scale=0.85]{../Patch/homoDiffEdgyU2}
\end{figure}


Suppose the spatial microscale lattice is at points~\(x_i\),
with constant spacing~\(dx\). With dependent
variables~\(u_i(t)\), simulate the microscale lattice
diffusion system
\begin{equation}
\D t{u_{i}}= \frac1{dx^2}\delta[c_{i-1/2}\delta u_{i}] ,
\label{eq:hetroDiff}
\end{equation}
in terms of the centred difference operator~\(\delta\). The
system has a microscale heterogeneity via the
coefficients~\(c_{i+1/2}\) which we assume to have some
given known periodicity. \cref{fig:homoDiffEdgyU2} shows one
patch simulation of this system: observe the effects of the
heterogeneity within each patch.

\begin{figure}
\centering \caption{\label{fig:homoDiffEdgyU1}diffusion
field~\(u(x,t)\) of the gap-tooth scheme applied to the
diffusive~\cref{eq:hetroDiff}. Over this short meso-time we
see the macroscale diffusion emerging from the damped
sub-patch fast quasi-equilibration.}
\includegraphics[scale=0.85]{../Patch/homoDiffEdgyU1}
\end{figure}





\begin{devMan}



\subsection{Script code to simulate heterogeneous diffusion systems}
\label{sec:sc2heterodiff}

This example script implements the following patch\slash
gap-tooth scheme (left-right arrows denote function
recursion).
\begin{enumerate}\def\itemsep{-1.5ex}
\item configPatches1, and add micro-information 
\item ode15s \into patchSmooth1 \into heteroDiff
\item plot the simulation 
\item use patchSmooth1 to explore the Jacobian
\end{enumerate}

First establish the microscale heterogeneity has
micro-period~\verb|mPeriod| on the lattice, and random
log-normal values, albeit normalised to have harmonic mean
one.  This normalisation then means that macroscale
diffusion on a domain of length~\(2\pi\) should have near
integer decay rates, the squares of \(0,1,2,\ldots\). Then
the heterogeneity is repeated \verb|nPeriodsPatch| times
within each patch. 
\begin{matlab}
%}
clear all
mPeriod = 3
cHetr = exp(1*randn(mPeriod,1));
cHetr = cHetr*mean(1./cHetr) % normalise
nPeriodsPatch=1
%{
\end{matlab}

Establish the global data struct~\verb|patches| for the
microscale heterogeneous lattice diffusion
system~\cref{eq:hetroDiff} solved on \(2\pi\)-periodic
domain, with seven patches, here each patch of size
ratio~\(0.25\) from one side to the other, with five
micro-grid points in each patch, and quartic
interpolation~(\(4\)) to provide the edge-values of the
inter-patch coupling conditions. Setting
\verb|patches.EdgyInt| to one means the edge-values come
from interpolating the opposite next-to-edge values of the
patches (not the mid-patch values).  In this case we appear
to need at least fourth order (quartic) interpolation to get
accurate decay rate for heterogeneous diffusion.
\begin{matlab}
%}
global patches
nPatch = 9
ratio = 0.25
nSubP = nPeriodsPatch*mPeriod+2
patches.EdgyInt = 1; % one to use edges for interpolation
configPatches1(@heteroDiff,[-pi pi],nan,nPatch ...
    ,4,ratio,nSubP);
%{
\end{matlab}

Replicate the heterogeneous coefficients across the width of
each patch.
\begin{matlab}
%}
patches.c=[repmat(cHetr,(nSubP-2)/mPeriod,1);cHetr(1)];
%{
\end{matlab}

\paragraph{Simulate}
Set the initial conditions of a simulation to be that of a
lump perturbed by significant random microscale noise,
via~\verb|randn|.
\begin{matlab}
%}
u0 = exp(-patches.x.^2)+0.1*randn(nSubP,nPatch);
%{
\end{matlab}
Integrate using standard stiff integrators.
\begin{matlab}
%}
if ~exist('OCTAVE_VERSION','builtin')
    [ts,us] = ode15s(@patchSmooth1, [0 0.5], u0(:));
else % octave version
    [ts,us] = odeOcts(@patchSmooth1, [0 0.5], u0(:));
end
%{
\end{matlab}

\paragraph{Plot space-time surface of the simulation}
We want to see the edge values of the patches, so we adjoin
a row of \verb|nan|s in between patches. For the field
values (which are rows in~\verb|us|) we need to reshape,
permute, interpolate to get edge values, pad with
\verb|nan|s, and reshape again.
\begin{matlab}
%}
xs = patches.x;  xs(end+1,:) = nan;
us = patchEdgeInt1( permute( reshape(us,length(ts) ...
     ,size(patches.x,1),size(patches.x,2)) ,[2 3 1]) );
us(end+1,:,:) = nan;
us=reshape(us,[],length(ts));
%{
\end{matlab}

Now plot two space-time graphs. The first is every time step
over a meso-time to see the oscillation and decay of the
fast sub-patch diffusions. The second is subsampled surface
over the macroscale duration of the simulation to show the
propagation of the macroscale diffusion over the
heterogeneous lattice.
\begin{matlab}
%}
for p=1:2
  switch p
  case 1, j=find(ts<0.01/nPeriodsPatch);
  case 2, [~,j]=min(abs(ts-linspace(ts(1),ts(end),50)));
  end
  figure(p),clf
  mesh(ts(j),xs(:),us(:,j)),  view(60,40)
  xlabel('time t'), ylabel('space x'), zlabel('u(x,t)')
  set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 14 10])
  print('-depsc2',['homoDiffEdgyU' num2str(p)])
end
%{
\end{matlab}

\paragraph{Compute Jacobian and its spectrum}
Let's explore the Jacobian dynamics for a range of orders of
interpolation, all for the same patch design and
heterogeneity.  Here use a smaller ratio, and more patches,
as we do not plot.
\begin{matlab}
%}
ratio=0.1
nPatch=19
leadingEvals=[];
for ord=0:2:6
ordInterp=ord
configPatches1(@heteroDiff,[-pi pi],nan,nPatch ...
    ,ord,ratio,nSubP);
%{
\end{matlab}

Form the Jacobian matrix, linear operator, by numerical
construction about a zero field.  Use~\verb|i| to store the
indices of the micro-grid points that are interior to the
patches and hence are the system variables.
\begin{matlab}
%}
u0=0*patches.x; u0([1 end],:)=nan; u0=u0(:);
i=find(~isnan(u0));
nJ=length(i);
Jac=nan(nJ);
for j=1:nJ
   u0(i)=((1:nJ)==j);
   dudt=patchSmooth1(0,u0);
   Jac(:,j)=dudt(i);
end
nonSymmetric=norm(Jac-Jac')
assert(nonSymmetric<1e-10,'failed symmetry')
Jac(abs(Jac)<1e-12)=0;
%{
\end{matlab}
\begin{table}
\caption{\label{tbl:homoDiffEdgy1}example parameters and
list of eigenvalues (every fourth one listed is sufficient
due to symmetry): \(\texttt{nPatch}=19\),
\(\texttt{ratio}=0.1\), \(\texttt{nSubP}=5\).  The columns
are for various \texttt{ordCC}, in order: 0,~spectral
interpolation; 2,~quadratic; 4,~quartic; and 6,~sixth order.}
\begin{verbatim}
cHetr =
       6.9617
       0.4217
       2.0624
leadingEvals =
        2e-11       -2e-12        4e-12       -2e-11
      -0.9999      -1.5195      -1.0127      -1.0003
      -3.9992      -11.861      -4.7785      -4.0738
      -8.9960      -45.239      -17.164      -10.703
      -15.987      -116.27      -56.220      -30.402
      -24.969      -230.63      -151.74      -92.830
      -35.936      -378.80      -327.36      -247.37
      -48.882      -535.89      -570.87      -521.89
      -63.799      -668.21      -818.33      -855.72
      -80.678      -743.96      -976.57      -1093.4
       -29129       -29233       -29227       -29222
       -29151       -29234       -29229       -29223
\end{verbatim}
\end{table}
Find the eigenvalues of the Jacobian, and list for
inspection in \cref{tbl:homoDiffEdgy1}: the spectral
interpolation is effectively exact for the macroscale;
quadratic interpolation is usually quantitatively in error;
quartic interpolation appears to be the lowest order for
reliable quantitative accuracy.
\begin{matlab}
%}
[evecs,evals]=eig(Jac);
eval=-sort(-diag(real(evals)));
leadingEvals=[leadingEvals eval(1:2:nPatch+4)]
%{
\end{matlab}
End of the for-loop over orders of interpolation
\begin{matlab}
%}
end
%{
\end{matlab}

End of the main script.



\input{../Patch/heteroDiff.m}


Fin.
\end{devMan}
%}

