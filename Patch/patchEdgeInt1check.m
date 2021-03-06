% Check the finite stencil interpolation of patchEdgeInt1()
%All tests passed.
%AJR, Nov 2019
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\subsection{\texttt{patchEdgeInt1check}: check the finite stencil interpolation}
\label{sec:patchEdgeInt1check}

A script to test the finite width stencil interpolation of
function \verb|patchEdgeInt1()| Establish global data struct
for the range of various cases.
\begin{matlab}
%}
clear all
global patches
nSubP=6
%{
\end{matlab}

\paragraph{Check standard finite stencil interpolation}
Check over various types and orders of interpolation,
numbers of patches, random domain lengths and random ratios.
\begin{matlab}
%}
for edgyInt=rem(nSubP+1,2):1
for ordCC=2:2:8
for nPatch=ordCC+(2:4)
edgyInt=edgyInt
ordCC=ordCC
nPatch=nPatch
Domain=5*[-rand rand]
ratio=0.5*rand
patches.EdgyInt=edgyInt; 
configPatches1(@sin,Domain,nan,nPatch,ordCC,ratio,nSubP);
%{
\end{matlab}

\subparagraph{Check multiple fields simultaneously}
Set profiles to be various powers of~\(x\), and evaluate the interpolation.
\begin{matlab}
%}
ps=1:ordCC
cs=randn(size(ps))
u0=patches.x.^shiftdim(ps,-1).*shiftdim(cs,-1)+randn;
ui=patchEdgeInt1(u0(:));
%{
\end{matlab}
The interior patches should have zero error.
\begin{matlab}
%}
j=ordCC/2+1:nPatch-ordCC/2;
iError=ui(:,j,:)-u0(:,j,:);
normError=norm(iError(:))
assert(normError<5e-12,'failed finite stencil interpolation')
%{
\end{matlab}

End the for-loops over various parameters.
\begin{matlab}
%}
end,end,end
return%%%%%%%%%%%%%%%%%%%%%
%{
\end{matlab}
\endinput



\paragraph{Now test finite stencil interpolation on staggered grid}
Must have even number of patches for a staggered grid.
\begin{matlab}
%}
for nPatch=6:2:20
nPatch=nPatch
ratio=0.5*rand
nSubP=3; % of form 4*N-1
Len=10*rand
configPatches1(@simpleWavepde,[0,Len],nan,nPatch,-1,ratio,nSubP);
kMax=floor((nPatch/2-1)/2)
%{
\end{matlab}
Identify which microscale grid points are \(h\)~or~\(u\) values.
\begin{matlab}
%}
uPts=mod( bsxfun(@plus,(1:nSubP)',(1:nPatch)) ,2);
hPts=find(1-uPts);
uPts=find(uPts);
%{
\end{matlab}
Set a profile for various wavenumbers. The capital
letter~\verb|U| denotes an array of values merged from
both~\(u\) and~\(h\) fields on the staggered grids.
\begin{matlab}
%}
fprintf('Single field-pair test.\n')
for k=-kMax:kMax
  U0=nan(nSubP,nPatch);
  U0(hPts)=rand*exp(+1i*k*patches.x(hPts)*2*pi/Len);
  U0(uPts)=rand*exp(-1i*k*patches.x(uPts)*2*pi/Len);
  Ui=patchEdgeInt1(U0(:));
  normError=norm(Ui-U0);
  if abs(normError)>5e-14
    normError=normError
    error(['failed single sys interpolation k=' num2str(k)])
  end
end
%{
\end{matlab}

\subparagraph{Test multiple fields}
Set a profile, and evaluate the interpolation. For the case
of the highest wavenumber zig-zag, squash the error when the
alternate centre-patch values are all zero. First shift the
\(x\)-coordinates so that the zig-zag mode is centred on a
patch.
\begin{matlab}
%}
i0=(nSubP+1)/2; % centre-patch index
fprintf('Two field-pairs test.\n')
x0=patches.x((nSubP+1)/2,1);
patches.x=patches.x-x0;
for k=1:nPatch/4
  U0=nan(nSubP,nPatch); V0=U0;
  U0(hPts)=rand*sin(k*patches.x(hPts)*2*pi/Len);
  U0(uPts)=rand*sin(k*patches.x(uPts)*2*pi/Len);
  V0(hPts)=rand*cos(k*patches.x(hPts)*2*pi/Len);
  V0(uPts)=rand*cos(k*patches.x(uPts)*2*pi/Len);
  UVi=patchEdgeInt1([U0(:);V0(:)]);
  normuError=norm(UVi(:,1:2:nPatch,1)-U0(:,1:2:nPatch))*norm(U0(i0,2:2:nPatch)) ...
      +norm(UVi(:,2:2:nPatch,1)-U0(:,2:2:nPatch))*norm(U0(i0,1:2:nPatch));
  normuError=norm(UVi(:,1:2:nPatch,2)-V0(:,1:2:nPatch))*norm(V0(i0,2:2:nPatch)) ...
      +norm(UVi(:,2:2:nPatch,2)-V0(:,2:2:nPatch))*norm(V0(i0,1:2:nPatch));
  if abs(normuError)+abs(normvError)>2e-13
    normuError=normuError, normvError=normvError
    error(['failed double field interpolation k=' num2str(k)])
  end
end
%{
\end{matlab}

End for-loop over patches
\begin{matlab}
%}
end
%{
\end{matlab}




\paragraph{Finish}
If no error messages, then all OK.
\begin{matlab}
%}
fprintf('\nIf you read this, then all tests were passed\n')
%{
\end{matlab}
%}
