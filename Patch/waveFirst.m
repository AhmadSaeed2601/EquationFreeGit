%Computes the time derivatives of a 1D, heterogeneous,
%first-order, wave PDE in 1D on patches. AJR, 17 Dec 2019
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\subsection{\texttt{waveFirst()}: first-order wave PDE}
\label{sec:waveFirst}
This function codes a lattice, first-order, heterogeneous,
wave \pde\ inside patches.  Optionally adds some viscous
dissipation.  For 2D input arrays~\verb|u| and~\verb|x| (via
edge-value interpolation of \verb|patchSmooth1|,
\cref{sec:patchSmooth1}), computes the time
derivative~\cref{eq:waveEdgy1} at each point in the interior
of a patch, output in~\verb|ut|.  
\begin{matlab}
%}
function ut = waveFirst(t,u,x)
  global patches
  dx = diff(x(2:3)); % space step
  i = 2:size(u,1)-1; % interior points in a patch
  ut = nan(size(u)); % preallocate output array
  ut(i,:)=-(patches.c(i).*u(i+1,:)-patches.c(i-1).*u(i-1,:))/(2*dx) ...
           +patches.nu*diff(u,2)/dx^2; 
end% function
%{
\end{matlab}
%}
