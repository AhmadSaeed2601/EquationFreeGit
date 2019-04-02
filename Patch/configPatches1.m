% Creates a data struct of the design of patches for later
% use by the patch functions such as smoothPatch1().  
% AJR, Nov 2017 -- Feb 2019
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\section{\texttt{configPatches1()}: configures spatial patches in 1D}
\label{sec:configPatches1}
\localtableofcontents

\subsection{Introduction}

Makes the struct~\verb|patches| for use by the patch\slash
gap-tooth time derivative function~\verb|patchSmooth1()|.
\cref{sec:configPatches1eg} lists an example of its use.
\begin{matlab}
%}
function configPatches1(fun,Xlim,BCs,nPatch,ordCC,ratio,nSubP ...
                       ,nEdge)
global patches
%{
\end{matlab}
\paragraph{Input}
If invoked with no input arguments, then executes an example
of simulating Burgers' \pde---see \cref{sec:configPatches1eg}
for the example code.
\begin{itemize}
\item \verb|fun| is the name of the user function,
\verb|fun(t,u,x)|, that computes time derivatives (or
time-steps) of quantities on the patches.

\item \verb|Xlim| give the macro-space domain of the
computation: patches are equi-spaced over the interior of
the interval~\([\verb|Xlim(1)|,\verb|Xlim(2)|]\).

\item \verb|BCs| somehow will define the macroscale boundary
conditions. Currently, \verb|BCs| is ignored and the system
is assumed macro-periodic in the domain.

\item \verb|nPatch| is the number of equi-spaced spaced
patches.

\item \verb|ordCC| is the `order' of interpolation across
empty space of the macroscale mid-patch values to the edge
of the patches for inter-patch coupling: currently must 
be~\(\geq -1\).

\item \verb|ratio| (real) is the ratio of the half-width of
a patch to the spacing of the patch mid-points: so
\(\verb|ratio|=\tfrac12\) means the patches abut; and
\(\verb|ratio|=1\) is overlapping patches as in holistic
discretisation.

\item \verb|nSubP| is the number of equi-spaced microscale
lattice points in each patch. Must be odd so that there is a
central lattice point.

\item \verb|nEdge|, optional, for each patch, the number of edge
values set by interpolation at the edge regions of each
patch.  May be omitted.  The default is one (suitable for
microscale lattices with only nearest neighbour
interactions).
\end{itemize}


\paragraph{Output} The \emph{global} struct \verb|patches|
is created and set with the following components.
\begin{itemize}
\item \verb|.fun| is the name of the user's function
\verb|fun(u,t,x)| that computes the time derivatives (or
steps) on the patchy lattice. 

\item \verb|.ordCC| is the specified order of inter-patch
coupling. 

\item \verb|.alt| is true for interpolation using only odd
neighbouring patches as for staggered grids, and false for
the usual case of all neighbour coupling.

\item \verb|.Cwtsr| and \verb|.Cwtsl| are the
\(\verb|ordCC|\)-vector of weights for the inter-patch
interpolation onto the right and left edges (respectively)
with patch:macroscale ratio as specified.

\item \verb|.x| is \(\verb|nSubP|\times \verb|nPatch|\)
array of the regular spatial locations~\(x_{ij}\) of the
microscale grid points in every patch.  

\item \verb|.nEdge| is, for each patch, the number of edge
values set by interpolation at the edge regions of each
patch.
\end{itemize}




\subsection{If no arguments, then execute an example}
\label{sec:configPatches1eg}
\begin{matlab}
%}
if nargin==0
%{
\end{matlab}
The code here shows one way to get started: a user's script
may have the following three steps (left-right arrows denote
function recursion).
\begin{enumerate}\def\itemsep{-1.5ex}
\item configPatches1 
\item ode15s integrator \into patchSmooth1 \into user's burgersPDE
\item process results
\end{enumerate}
Establish global patch data struct to interface with a
function coding Burgers' \pde: to be solved on
\(2\pi\)-periodic domain, with eight patches, spectral
interpolation couples the patches, each patch of half-size
ratio~\(0.2\), and with seven microscale points forming each
patch.
\begin{matlab}
%}
configPatches1(@BurgersPDE,[0 2*pi], nan, 8, 0, 0.2, 7);
%{
\end{matlab}
Set an initial condition, with some randomness, and 
simulate in time using a standard stiff integrator and the
interface function \verb|patchsmooth1()|
(\cref{sec:patchSmooth1}).
\begin{matlab}
%}
u0=0.3*(1+sin(patches.x))+0.1*randn(size(patches.x));
[ts,ucts]=ode15s(@patchSmooth1,[0 0.5],u0(:));
%{
\end{matlab}
Plot the simulation using only the microscale values
interior to the patches: set \(x\)-edges to \verb|nan| to
leave the gaps.  \autoref{fig:config1Burgers} illustrates an
example simulation in time generated by the patch scheme
applied to Burgers'~\pde.
\begin{matlab}
%}
figure(1),clf
patches.x([1 end],:)=nan;
surf(ts,patches.x(:),ucts'), view(60,40)
title('Example of Burgers PDE on patches in space')
xlabel('time t'), ylabel('space x'), zlabel('u(x,t)')
%{
\end{matlab}
\begin{figure}
\centering \caption{\label{fig:config1Burgers}field
\(u(x,t)\) of the patch scheme applied to Burgers'~\pde.}
\includegraphics[scale=0.85]{config1Burgers}
\end{figure}
Upon finishing execution of the example, exit this function.
\begin{matlab}
%}
return
end%if no arguments
%{
\end{matlab}
\paragraph{Example of Burgers PDE inside patches}
As a microscale discretisation of Burgers' \pde\ 
\(u_t=u_{xx}-30uu_x\), here code \(\dot u_{ij} 
=\frac1{\delta x^2} (u_{i+1,j}-2u_{i,j}+u_{i-1,j}) 
-30u_{ij} \frac1{2\delta x}(u_{i+1,j}-u_{i-1,j})\).
\begin{matlab}
%}
function ut=BurgersPDE(t,u,x)
  dx=diff(x(1:2));  % microscale spacing
  i=2:size(u,1)-1;  % interior points in patches
  ut=nan(size(u));  % preallocate storage
  ut(i,:)=diff(u,2)/dx^2 ...
    -30*u(i,:).*(u(i+1,:)-u(i-1,:))/(2*dx);
end
%{
\end{matlab}


\begin{devMan}


%This hack needs to be resolved: AJR, 2019-02-26
%\begin{matlab}
%%}
%patches.EnsAve = 0;
%%{
%\end{matlab}


\subsection{The code to make patches and interpolation}
Set one edge-value to compute by interpolation if not
specified by the user. Store in the struct.
\begin{matlab}
%}
if nargin<8, nEdge=1; end
if nEdge>1, error('multi-edge-value interp not yet implemented'), end
if 2*nEdge+1>nSubP, error('too many edge values requested'), end
patches.nEdge=nEdge;
%{
\end{matlab}
First, store the pointer to the time derivative function in
the struct.
\begin{matlab}
%}
patches.fun=fun;
%{
\end{matlab}
Second, store the order of interpolation that is to provide
the values for the inter-patch coupling conditions. Spectral
coupling is \verb|ordCC| of~\(0\) and~\(-1\).
\begin{matlab}
%}
if (ordCC<-1) | ~(floor(ordCC)==ordCC)
    error('ordCC out of allowed range integer>-2')
end
%{
\end{matlab}
For odd~\verb|ordCC| do interpolation based upon odd
neighbouring patches as is useful for staggered grids.
\begin{matlab}
%}
patches.alt=mod(ordCC,2);
ordCC=ordCC+patches.alt;
patches.ordCC=ordCC;
%{
\end{matlab}
Check for staggered grid and periodic case.
\begin{matlab}
%}
  if patches.alt & (mod(nPatch,2)==1)
    error('Require an even number of patches for staggered grid')
  end
%{
\end{matlab}
Might as well precompute the weightings for the
interpolation of field values for coupling. (Could sometime
extend to coupling via derivative values.)
\begin{matlab}
%}
patches.Cwtsr=zeros(ordCC,1);
if patches.alt  % eqn (7) in \cite{Cao2014a}
    patches.Cwtsr(1:2:ordCC)=[1 ...
      cumprod((ratio^2-(1:2:(ordCC-2)).^2)/4)./ ...
      factorial(2*(1:(ordCC/2-1)))];    
    patches.Cwtsr(2:2:ordCC)=[ratio/2 ...
      cumprod((ratio^2-(1:2:(ordCC-2)).^2)/4)./ ...
      factorial(2*(1:(ordCC/2-1))+1)*ratio/2];
else % 
    patches.Cwtsr(1:2:ordCC)=(cumprod(ratio^2- ...
      (((1:(ordCC/2))-1)).^2)./factorial(2*(1:(ordCC/2))-1)/ratio);
    patches.Cwtsr(2:2:ordCC)=(cumprod(ratio^2- ...
      (((1:(ordCC/2))-1)).^2)./factorial(2*(1:(ordCC/2))));
end
patches.Cwtsl=(-1).^((1:ordCC)'-patches.alt).*patches.Cwtsr;
%{
\end{matlab}
Third, set the centre of the patches in a the macroscale
grid of patches assuming periodic macroscale domain.
\begin{matlab}
%}
X=linspace(Xlim(1),Xlim(2),nPatch+1);
X=X(1:nPatch)+diff(X)/2;
DX=X(2)-X(1);
%{
\end{matlab}
Construct the microscale in each patch, assuming Dirichlet
patch edges, and a half-patch length
of~\(\verb|ratio|\cdot\verb|DX|\).
\begin{matlab}
%}
if mod(nSubP,2)==0, error('configPatches1: nSubP must be odd'), end
i0=(nSubP+1)/2;
dx=ratio*DX/(i0-1);
patches.x=bsxfun(@plus,dx*(-i0+1:i0-1)',X); % micro-grid
end% function
%{
\end{matlab}
Fin.
\end{devMan}
%}