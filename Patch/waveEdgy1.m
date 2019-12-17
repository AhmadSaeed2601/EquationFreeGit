%Simulate a 1D, first-order, wave PDE on small patches as an
%example application of patches in space. The patch coupling
%interpolates next-to-edge values to get opposite edge
%values.  Here the microscale has 'wave-speeds' dependent
%upon x, and randomly chosen but specified period.   Then
%explore stability and consistency.  AJR, 17 Dec 2019
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\section{\texttt{waveEdgy1}: simulate a 1D, first-order,
wave PDE on small patches}
\label{sec:waveEdgy1}
\localtableofcontents

\cref{fig:waveEdgyU2} shows an example simulation in time
generated by the patch scheme applied to macroscale
diffusion propagation through a medium with microscale
heterogeneity. The inter-patch coupling is realised by
spectral interpolation of the patch's next-to-edge values to
the patch opposite edges. Such coupling preserves symmetry
in many systems, and in this first-order wave \pde\
preserves skew-symmetry.
\begin{figure}
\centering \caption{\label{fig:waveEdgyU2}wave
field~\(u(x,t)\) of the gap-tooth scheme applied to the
wave~\cref{eq:waveEdgy1}. The microscale random component to
the initial condition, the sub-patch fluctuations, decays,
leaving the emergent macroscale wave in the heterogeneous
media. This simulation uses nine patches of `large' size
ratio~\(0.25\) for visibility.}
\includegraphics[scale=0.85]{../Patch/waveEdgyU2}
\end{figure}

The first-order wave-like \pde\ is
\(u_t=-\tfrac12(cu)_x-\tfrac12cu_x\)\,, which when \(c\)~is
constant becomes the canonical first-order wave \pde
\(u_t=-cu_x\)\,.  The differential operator on the
right-hand side is skew-symmetric: letting
\(\cD=-\tfrac12(c\cdot)_x -\tfrac12c\partial_x\) then \(\int
v\cD u\,dx =\int -v(cu)_x -v\tfrac12cu_x\,dx =-\int
\tfrac12v_xcu +\tfrac12(vc)_xu \,dx =-\int u\cD v\,dx \)\,.

To discretise in space, suppose the spatial microscale
lattice is at points~\(x_i\), with constant spacing~\(d\).
With dependent variables~\(u_i(t)\), simulate the microscale
lattice, in terms of the centred difference~\(\delta\) and
mean~\(\mu\), wave system
\begin{align}
\de t{u_{i}}&= -\frac1{2d}\left[ \delta(c_i\mu u_{i}) +\mu(c_i\delta u_i) \right]
= -\frac1{2d}\left[ c_{i+\tfrac12}u_{i+1} -c_{i-\tfrac12}u_{i-1} \right].
\label{eq:waveEdgy1}
\end{align}
\cref{fig:waveEdgyU2} shows one patch simulation of this
space-time system, except it also includes a \(\nu=0.001\)
small `viscous' dissipation,~\(\nu\delta^2u_i/d^2\), to
weakly damp the microscale, sub-patch, fast waves.







\subsection{Script code to simulate heterogeneous wave systems}
\label{sec:sc2waveFirst}

This example script implements the following patch\slash
gap-tooth scheme (left-right arrows denote function
recursion).
\begin{enumerate}\def\itemsep{-1.5ex}
\item configPatches1, and add micro-information 
\item ode15s \into patchSmooth1 \into waveFirst
\item plot the simulation 
\item use patchSmooth1 to explore the Jacobian
\end{enumerate}

First establish the microscale heterogeneity has
(odd-valued) micro-period \verb|mPeriod| on the lattice, and
random log-normal values, normalised.  This normalisation
means that macroscale wave on a domain of length~\(2\pi\)
should have nearly integer frequencies,
\(0,1,2,\ldots\)---except that the normalisation is exact
only for periods~3 and~5. Then the heterogeneity is
repeated \verb|nPeriodsPatch| times within each patch. 
\begin{matlab}
%}
clear all
mPeriod = 5 % needs to be odd for a wave
cHetr = exp(0.3*randn(mPeriod,1)); % 0.3 appears max reasonable
if mPeriod==3, 
    cHetr=cHetr*mean(cHetr.^2)/prod(cHetr) % normalise
elseif mPeriod==5, 
    cHetr=cHetr*mean(cHetr.^2.*cHetr([3 4 5 1 2]).^2)/prod(cHetr)
else cHetr=cHetr*mean(1./cHetr) % not correct normalise
end
nPeriodsPatch=1 % also needs to be odd
%{
\end{matlab}

Establish the global data struct~\verb|patches| for the
microscale heterogeneous lattice wave
system~\cref{eq:waveEdgy1} solved on \(2\pi\)-periodic
domain, with nine patches, here each patch of size
ratio~\(0.25\) from one side to the other, with five
micro-grid points in each patch, and quartic
interpolation~(\(4\)) to provide the edge-values via the
inter-patch coupling conditions. Setting
\verb|patches.EdgyInt| to one means the edge-values come
from interpolating the opposite next-to-edge values of the
patches (not the mid-patch values).  
\begin{matlab}
%}
global patches
nPatch = 9
ratio = 0.25
nSubP = nPeriodsPatch*mPeriod+2
patches.EdgyInt = 1; % one to use edges for interpolation
configPatches1(@waveFirst,[-pi pi],nan,nPatch ...
    ,4,ratio,nSubP);
%{
\end{matlab}

Replicate the heterogeneous coefficients across the width of
each patch. Also specify the weak damping of the sub-patch,
fast, microscale waves.
\begin{matlab}
%}
patches.c=[repmat(cHetr,nPeriodsPatch,1);cHetr(1)];
patches.nu=0.001;
%{
\end{matlab}

\paragraph{Simulate}
Set the initial conditions of a simulation to be that of a
sine wave perturbed by significant random microscale noise,
via~\verb|randn|.
\begin{matlab}
%}
u0 = sin(patches.x)+0.1*randn(nSubP,nPatch);
%{
\end{matlab}
Integrate using standard stiff integrators.
\begin{matlab}
%}
if ~exist('OCTAVE_VERSION','builtin')
    [ts,us] = ode15s(@patchSmooth1, [0 3.5], u0(:));
else % octave version
    [ts,us] = odeOcts(@patchSmooth1, [0 0.5], u0(:));
end
%{
\end{matlab}

\paragraph{Plot space-time surface of the simulation} Let's
see the edge values of the patches. For the field values
(which are rows in~\verb|us|) we need to reshape, permute,
interpolate with \verb|patchEdgeInt1| to get edge values,
pad with \verb|nan|s, and reshape again.
\begin{matlab}
%}
xs = patches.x;  xs(end+1,:) = nan;
us = patchEdgeInt1( permute( reshape(us,length(ts) ...
     ,size(patches.x,1),size(patches.x,2)) ,[2 3 1]) );
us(end+1,:,:) = nan;
us=reshape(us,[],length(ts));
%{
\end{matlab}

Now plot a space-time graph. Subsample the data over the
macroscale duration of the simulation to show the
propagation of the macroscale wave over the heterogeneous
lattice.
\begin{matlab}
%}
[~,j]=min(abs(ts-linspace(ts(1),ts(end),50)));
figure(2),clf
mesh(ts(j),xs(:),us(:,j)),  view(60,40)
xlabel('time t'), ylabel('space x'), zlabel('u(x,t)')
set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 14 10])
print('-depsc2',['waveEdgyU' num2str(2)])
%{
\end{matlab}

\paragraph{Compute Jacobian and its spectrum} Let's explore
the Jacobian dynamics for a range of orders of
interpolation, all for the same patch design and
heterogeneity.  Here use a smaller ratio, and more patches,
as we do not plot.  Set the weak damping to zero so we
explore the ideal case of the wave
system~\eqref{eq:waveEdgy1}.
\begin{matlab}
%}
ratio=0.03
nPatch=19
leadingFreqs=[];
for ord=0:2:6
ordInterp=ord
configPatches1(@waveFirst,[-pi pi],nan,nPatch ...
    ,ord,ratio,nSubP);
patches.nu=0;
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
nonSkewSymmetric=norm(Jac+Jac')
assert(nonSkewSymmetric<1e-10,'failed skew-symmetry')
Jac(abs(Jac)<1e-12)=0;
%{
\end{matlab}
\begin{table}
\caption{\label{tbl:waveEdgy1}example parameters and list of
eigenvalues (every second one listed is sufficient due to
symmetry): \(\texttt{nPatch}=19\), \(\texttt{ratio}=0.03\),
\(\texttt{nSubP}=7\).  The columns are for various
\texttt{ordCC}, in order: 0,~spectral interpolation;
2,~quadratic; 4,~quartic; and 6,~sixth order. Rows are
ordered in the effective wavenumber of the corresponding
eigenvector (the number of zero crossings).}
\begin{verbatim}
cHetr =
    0.6614
    1.5758
    1.8645
    1.4600
    0.8486
leadingFreqs =
         0         0         0         0
    1.0000    0.9819    0.9996    1.0000
    2.0000    1.8574    1.9879    1.9989
    2.9999    2.5318    2.9138    2.9830
    3.9997    2.9320    3.6688    3.8910
    4.9995    3.0146    4.1015    4.5720
    5.9991    2.7705    4.0640    4.7890
    6.9985    2.2261    3.4699    4.3042
    7.9978    1.4402    2.3421    3.0200
    8.9969    0.4981    0.8278    1.0897
  698.0262  698.0852  698.0370  698.0283
  698.1548  698.1728  698.1563  698.1549
\end{verbatim}
\end{table}
Find the eigenvalues of the Jacobian, and list for
inspection in \cref{tbl:waveEdgy1} (using a count of zero
crossings in the corresponding eigenvector in order to try to sort on the spatial wavenumber): the
spectral interpolation is effectively exact for the
macroscale; quadratic interpolation is usually
qualitatively good; quartic interpolation appears to be
the lowest order for quantitative accuracy.
\begin{matlab}
%}
[evecs,evals]=eig(Jac);
maxRealPartEvals=max(abs(real(diag(evals))))
assert(maxRealPartEvals<1e-10,'failed real-part zero')
freqs=imag(diag(evals));
[~,j]=sort(sum(abs(diff(sign(real(evecs))))));
leadingFreqs=[leadingFreqs -freqs(j(1:2:nPatch+4))];
%{
\end{matlab}
End of the for-loop over orders of interpolation, and
display the spectra.
\begin{matlab}
%}
end
leadingFreqs = leadingFreqs
%{
\end{matlab}
End of the main script.



\input{../Patch/waveFirst.m}


Fin.
%}

