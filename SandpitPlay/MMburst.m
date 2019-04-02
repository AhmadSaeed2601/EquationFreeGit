% Short explanation for users typing "help fun"
% Author, date
%!TEX root = ../Doc/eqnFreeDevMan.tex
%{
\paragraph{Code a burst of Michaelis--Menten enzyme kinetics}
Integrate a burst of length~\verb|bT| of the \ode{}s for the
Michaelis--Menten enzyme kinetics at parameter~\(\epsilon\)
inherited from above. Code \textsc{ode}s in
function~\verb|dMMdt| with variables \(x=\verb|x(1)|\) and
\(y=\verb|x(2)|\).  Starting at time~\verb|ti|, and
state~\verb|xi| (row), we here simply use \verb|ode23| to 
integrate in time.
\begin{matlab}
%}
function [ts, xs] = MMburst(ti, xi, bT) 
    global MMepsilon
    dMMdt = @(t,x) [ -x(1)+(x(1)+0.5)*x(2)
        1/MMepsilon*( x(1)-(x(1)+1)*x(2) ) ];
    if ~exist('OCTAVE_VERSION','builtin')
    [ts, xs] = ode23(dMMdt, [ti ti+bT], xi);
    else % octave version
    ts = linspace(ti,ti+bT,11);
    xs = lsode(@(x,t) dMMdt(t,x),xi,ts);
    end
end
%{
\end{matlab}
%}
