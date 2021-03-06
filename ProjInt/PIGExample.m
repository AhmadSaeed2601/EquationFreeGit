% Basic example of PIG. JM & AJR, Sept 2018 -- Apr 2019.
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\section{Example: Projective Integration using General macrosolvers }
\label{sec:ExPIG}
\localtableofcontents

In this example the Projective Integration-General scheme is
applied to a singularly perturbed ordinary differential
equation. The aim is to use a standard non-stiff numerical
integrator, such as \verb|ode45()|, on the slow, long-time
macroscale.  For this stiff system, \verb|PIG()| is an order
of magnitude faster than ordinary use of~\verb|ode45|.

\begin{devMan}
\begin{matlab}
%}
clear all, close all
%{
\end{matlab}

Set time scale separation and the underlying \ode{}s:
\begin{equation*}
\de t{x_1}=\cos x_1\sin x_2\cos t\,,
\quad
\de t{x_2}=\frac1\epsilon(-x_2+\cos x_1).
\end{equation*}
\begin{matlab}
%}
epsilon = 1e-4;
dxdt=@(t,x) [ cos(x(1))*sin(x(2))*cos(t)
             (cos(x(1))-x(2))/epsilon ];
%{
\end{matlab}

Set the `black-box' microsolver to be an integration using a
standard solver, and set the standard time of simulation for
the microsolver.
\begin{matlab}
%}
bT = epsilon*log(1/epsilon);
if ~exist('OCTAVE_VERSION','builtin')
    micB='ode45'; else micB='rk2Int'; end
microBurst = @(tb0, xb0) feval(micB,dxdt,[tb0 tb0+bT],xb0);
%{
\end{matlab}

Set initial conditions, and the time to be covered by the
macrosolver. 
\begin{matlab}
%}
x0 = [1 0.9];
tSpan = [0 5]; 
%{
\end{matlab}
Now time and integrate the above system over \verb|tSpan|
using \verb|PIG()| and, for comparison, a brute force
implementation of \verb|ode45|\slash\verb|lsode|. Report 
the time taken by each method (in seconds).
\begin{matlab}
%}
if ~exist('OCTAVE_VERSION','builtin')
    macInt='ode45'; else macInt='odeOct'; end
tic
[ts,xs,tms,xms] = PIG(macInt,microBurst,tSpan,x0);
secsPIGusingODEasMacro = toc
tic
[tClassic,xClassic] = feval(macInt,dxdt,tSpan,x0);
secsODEalone = toc
%{
\end{matlab}


Plot the output on two figures, showing the truth and
macrosteps on both, and all applications of the microsolver
on the first figure.
\begin{matlab}
%}
figure
h = plot(ts,xs,'o', tClassic,xClassic,'-', tms,xms,'.');
legend(h(1:2:5),'Pro Int method','classic method','PI microsolver')
xlabel('Time'), ylabel('State')

figure
h = plot(ts,xs,'o', tClassic,xClassic,'-');
legend(h([1 3]),'Pro Int method','classic method')
xlabel('Time'), ylabel('State')
if ~exist('OCTAVE_VERSION','builtin')
set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 14 10])
%print('-depsc2','PIGExample')
end
%{
\end{matlab}
\cref{fig:PIGExample} plots the output.
\begin{figure}\centering
\caption{\label{fig:PIGExample}Accurate simulation of a
stiff nonautonomous system by PIG().  The microsolver is
called on-the-fly by the macrosolver \texttt{ode45\slash
lsode}.}
\includegraphics[scale=0.8]{PIGExample}
\end{figure}

\begin{itemize}
\item The problem may be made more stiff or less stiff by
changing the time-scale separation parameter
\(\epsilon=\verb|epsilon|\). The compute time of
\verb|PIG()| is almost independent of~\(\epsilon\), whereas
that of \verb|ode45()| is proportional to~\(1/\epsilon\).

If the problem is `semi-stiff' (larger~\(\epsilon\)), then
\verb|PIG()|'s default of using \verb|cdmc()| avoids
nonsense (\cref{sec:Excdmc}).

\item  The stiff but low dimensional problem in this example
may be solved efficiently by a standard stiff solver (e.g.,
\verb|ode15s()|). The real advantage of the Projective
Integration schemes is in high dimensional stiff problems,
that are not efficiently solved by most standard methods.
\end{itemize}

\end{devMan}
%}