% ================================================================
% ANALISE TERMICA 2D DE MODULO FOTOVOLTAICO
% METODO DAS DIFERENCAS FINITAS - OCTAVE
%
% Regime permanente + regime transiente
%
% ================================================================

clear;
clc;
close all;

fprintf('\n');
fprintf('====================================================\n');
fprintf(' ANALISE TERMICA 2D - MODULO FOTOVOLTAICO\n');
fprintf(' METODO DAS DIFERENCAS FINITAS\n');
fprintf('====================================================\n\n');


%% ================================================================
% 1. GEOMETRIA DO PAINEL
% ================================================================

Lx = 1.580;          % comprimento do painel [m]
Ly = 0.790;          % largura do painel [m]

% Numero de celulas
ncel_x = 12;
ncel_y = 6;

% Dimensao das celulas
Lc = 0.125;          % 125 mm [m]

% Espacamento entre celulas
gap = 0.002;         % 2 mm [m]

% Passo da malha
dx = 0.002;          % [m]
dy = 0.002;          % [m]

% Espessura do painel
% ATENCAO: valor de modelagem, pois o enunciado nao fornece
espessura = 0.005;   % [m]


%% ================================================================
% 2. MALHA
% ================================================================

Nx = round(Lx/dx) + 1;
Ny = round(Ly/dy) + 1;

% Coordenadas reais da malha
x = linspace(0,Lx,Nx);
y = linspace(0,Ly,Ny);

[X,Y] = meshgrid(x,y);

fprintf('MALHA\n');
fprintf('----------------------------------------------------\n');
fprintf('Nx = %d nos\n',Nx);
fprintf('Ny = %d nos\n',Ny);
fprintf('Numero total de nos = %d\n',Nx*Ny);
fprintf('dx = %.4f m\n',dx);
fprintf('dy = %.4f m\n\n',dy);


%% ================================================================
% 3. PROPRIEDADES TERMICAS DO SILICIO
% ================================================================

k = 148;             % condutividade [W/(m.K)]
rho = 2330;          % densidade [kg/m^3]
cp = 713.9;          % calor especifico [J/(kg.K)]

% Difusividade termica
alpha = k/(rho*cp);

fprintf('PROPRIEDADES TERMICAS\n');
fprintf('----------------------------------------------------\n');
fprintf('k     = %.2f W/(m.K)\n',k);
fprintf('rho   = %.2f kg/m^3\n',rho);
fprintf('cp    = %.2f J/(kg.K)\n',cp);
fprintf('alpha = %.5e m^2/s\n\n',alpha);


%% ================================================================
% 4. CONDICOES AMBIENTAIS
% ================================================================

Tinf = 293.15;       % temperatura ambiente [K]

% Conveccao frontal
hf = 5.8;            % [W/(m^2.K)]

% Conveccao traseira
hr = 2.9;            % [W/(m^2.K)]

% Conveccao equivalente das duas faces
h = hf + hr;

fprintf('CONDICOES DE CONTORNO\n');
fprintf('----------------------------------------------------\n');
fprintf('Tinf = %.2f K = %.2f C\n',Tinf,Tinf-273.15);
fprintf('hf   = %.2f W/(m^2.K)\n',hf);
fprintf('hr   = %.2f W/(m^2.K)\n',hr);
fprintf('h    = %.2f W/(m^2.K)\n\n',h);


%% ================================================================
% 5. DADOS FOTOVOLTAICOS
% ================================================================

G = 1000;            % irradiancia [W/m^2]

% Dados fornecidos no arquivo
Voc = 0.64;          % [V]
Isc = 7.17;          % [A]

Vmpp = 0.50;         % [V]
Impp = 3.385;        % [A]

eta_ref = 0.1416;    % 14.16 %

FF = 0.7388;         % 73.88 %

% Area geometrica da celula segundo o enunciado
Ac = Lc*Lc;

% Potencia solar incidente na celula
Psolar_cell = G*Ac;

% Potencia eletrica aproximada usando a eficiencia fornecida
Pel_cell = eta_ref*Psolar_cell;

% Potencia termica
Pterm_cell = Psolar_cell - Pel_cell;

% Fluxo termico superficial
q_cell = Pterm_cell/Ac;


fprintf('DADOS FOTOVOLTAICOS\n');
fprintf('----------------------------------------------------\n');
fprintf('Irradiancia = %.2f W/m^2\n',G);
fprintf('Area celula = %.6f m^2\n',Ac);
fprintf('Voc         = %.3f V\n',Voc);
fprintf('Isc         = %.3f A\n',Isc);
fprintf('Vmpp        = %.3f V\n',Vmpp);
fprintf('Impp        = %.3f A\n',Impp);
fprintf('eta         = %.2f %%\n',100*eta_ref);
fprintf('FF          = %.2f %%\n',100*FF);
fprintf('\n');

fprintf('BALANCO DE ENERGIA\n');
fprintf('----------------------------------------------------\n');
fprintf('Psolar/celula  = %.4f W\n',Psolar_cell);
fprintf('Pel/celula     = %.4f W\n',Pel_cell);
fprintf('Pterm/celula   = %.4f W\n',Pterm_cell);
fprintf('q_cell         = %.4f W/m^2\n\n',q_cell);


%% ================================================================
% 6. IDENTIFICACAO DAS CELULAS NA MALHA
% ================================================================
%
% Cada celula recebe q_cell.
% Os espacos entre as celulas recebem q = 0.
%
% Os centros das celulas sao determinados geometricamente.
%
% ================================================================

q = zeros(Ny,Nx);

% Posicoes dos centros das celulas
%
% O painel possui margens laterais. Para manter a distribuicao
% centrada, usamos a area total ocupada pelas celulas.

comprimento_celulas = ncel_x*Lc + (ncel_x-1)*gap;
largura_celulas     = ncel_y*Lc + (ncel_y-1)*gap;

margem_x = (Lx - comprimento_celulas)/2;
margem_y = (Ly - largura_celulas)/2;

fprintf('GEOMETRIA DAS CELULAS\n');
fprintf('----------------------------------------------------\n');
fprintf('Area ocupada pelas celulas em x = %.4f m\n',comprimento_celulas);
fprintf('Area ocupada pelas celulas em y = %.4f m\n',largura_celulas);
fprintf('Margem x = %.4f m\n',margem_x);
fprintf('Margem y = %.4f m\n\n',margem_y);


% Centros das celulas
xc = zeros(1,ncel_x);
yc = zeros(1,ncel_y);

for c = 1:ncel_x
    xc(c) = margem_x + Lc/2 + (c-1)*(Lc+gap);
end

for r = 1:ncel_y
    yc(r) = margem_y + Lc/2 + (r-1)*(Lc+gap);
end


% Criacao da regiao das celulas
for r = 1:ncel_y

    for c = 1:ncel_x

        xmin = xc(c) - Lc/2;
        xmax = xc(c) + Lc/2;

        ymin = yc(r) - Lc/2;
        ymax = yc(r) + Lc/2;

        mascara = (X >= xmin) & (X <= xmax) & ...
                  (Y >= ymin) & (Y <= ymax);

        q(mascara) = q_cell;

    end

end


%% ================================================================
% 7. PLOT DA MALHA
% ================================================================

figure;

hold on;

% Para evitar excesso de linhas na tela, plotamos
% a malha com todas as linhas.

for j = 1:Ny
    plot(x, Y(j,:), 'k-');
end

for i = 1:Nx
    plot(X(:,i), y, 'k-');
end

xlabel('x [m]');
ylabel('y [m]');
title('Malha de Diferencas Finitas');

axis equal;
grid on;

hold off;


%% ================================================================
% 8. PLOT DA DISTRIBUICAO DAS CELULAS
% ================================================================

figure;

contourf(X,Y,q,20);

xlabel('x [m]');
ylabel('y [m]');
title('Distribuicao do Fluxo Termico');

colorbar;
grid on;


%% ================================================================
% 9. REGIME PERMANENTE
% ================================================================
%
% Equacao utilizada:
%
% k*t*d2T/dx2 + k*t*d2T/dy2
% + q - h(T-Tinf) = 0
%
% Onde:
%
% q = fluxo termico [W/m^2]
% h = hf + hr
%
% Condicao nas bordas:
% fluxo normal = 0
%
% ================================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf(' REGIME PERMANENTE\n');
fprintf('====================================================\n');


% Temperatura inicial
T = Tinf*ones(Ny,Nx);

% Tolerancia
tol = 1e-5;

% Maximo de iteracoes
max_iter = 10000;


% Coeficientes
ax = k*espessura/dx^2;
ay = k*espessura/dy^2;

% Termo convectivo
Sconv = h;

% Coeficiente central
ap = 2*ax + 2*ay + Sconv;


fprintf('Resolucao do regime permanente...\n');


for iter = 1:max_iter

    Told = T;

    % ------------------------------------------------------------
    % NOS INTERNOS
    % ------------------------------------------------------------

    T(2:Ny-1,2:Nx-1) = ...
        ( ...
        ax*(Told(2:Ny-1,3:Nx) + Told(2:Ny-1,1:Nx-2)) + ...
        ay*(Told(3:Ny,2:Nx-1) + Told(1:Ny-2,2:Nx-1)) + ...
        q(2:Ny-1,2:Nx-1) + ...
        h*Tinf ...
        ) / ap;


    % ------------------------------------------------------------
    % BORDAS
    %
    % Fluxo termico normal nulo:
    %
    % dT/dn = 0
    %
    % Implementado como espelhamento do no vizinho.
    % ------------------------------------------------------------

    % Esquerda
    T(2:Ny-1,1) = ...
        ( ...
        2*ax*Told(2:Ny-1,2) + ...
        ay*(Told(3:Ny,1) + Told(1:Ny-2,1)) + ...
        q(2:Ny-1,1) + ...
        h*Tinf ...
        ) / (2*ax + 2*ay + h);


    % Direita
    T(2:Ny-1,Nx) = ...
        ( ...
        2*ax*Told(2:Ny-1,Nx-1) + ...
        ay*(Told(3:Ny,Nx) + Told(1:Ny-2,Nx)) + ...
        q(2:Ny-1,Nx) + ...
        h*Tinf ...
        ) / (2*ax + 2*ay + h);


    % Inferior
    T(1,2:Nx-1) = ...
        ( ...
        ax*(Told(1,3:Nx) + Told(1,1:Nx-2)) + ...
        2*ay*Told(2,2:Nx-1) + ...
        q(1,2:Nx-1) + ...
        h*Tinf ...
        ) / (2*ax + 2*ay + h);


    % Superior
    T(Ny,2:Nx-1) = ...
        ( ...
        ax*(Told(Ny,3:Nx) + Told(Ny,1:Nx-2)) + ...
        2*ay*Told(Ny-1,2:Nx-1) + ...
        q(Ny,2:Nx-1) + ...
        h*Tinf ...
        ) / (2*ax + 2*ay + h);


    % ------------------------------------------------------------
    % CANTOS
    % ------------------------------------------------------------

    T(1,1) = 0.5*(T(1,2) + T(2,1));

    T(1,Nx) = 0.5*(T(1,Nx-1) + T(2,Nx));

    T(Ny,1) = 0.5*(T(Ny,2) + T(Ny-1,1));

    T(Ny,Nx) = ...
        0.5*(T(Ny,Nx-1) + T(Ny-1,Nx));


    % ------------------------------------------------------------
    % ERRO
    % ------------------------------------------------------------

    erro = max(max(abs(T-Told)));

    if erro < tol
        break;
    end

end


fprintf('Convergencia atingida.\n');
fprintf('Iteracoes = %d\n',iter);
fprintf('Erro = %.5e K\n\n',erro);


%% ================================================================
% 10. RESULTADOS - REGIME PERMANENTE
% ================================================================

Tmax_perm = max(T(:));
Tmin_perm = min(T(:));
Tmed_perm = mean(T(:));

fprintf('RESULTADOS DO REGIME PERMANENTE\n');
fprintf('----------------------------------------------------\n');

fprintf('Temperatura maxima = %.3f K\n',Tmax_perm);
fprintf('Temperatura maxima = %.3f C\n',Tmax_perm-273.15);

fprintf('Temperatura minima = %.3f K\n',Tmin_perm);
fprintf('Temperatura minima = %.3f C\n',Tmin_perm-273.15);

fprintf('Temperatura media  = %.3f K\n',Tmed_perm);
fprintf('Temperatura media  = %.3f C\n\n',Tmed_perm-273.15);


%% ================================================================
% 11. MAPA DE TEMPERATURA - REGIME PERMANENTE
% ================================================================

figure;

contourf(X,Y,T-273.15,20);

xlabel('x [m]');
ylabel('y [m]');

title('Distribuicao de Temperatura - Regime Permanente');

colorbar;
grid on;


%% ================================================================
% 12. LINHAS DE TEMPERATURA
% ================================================================

figure;

contour(X,Y,T-273.15,15);

xlabel('x [m]');
ylabel('y [m]');

title('Linhas de Temperatura - Regime Permanente');

colorbar;
grid on;


%% ================================================================
% 13. PERFIL CENTRAL - PERMANENTE
% ================================================================

jcentro = round(Ny/2);

figure;

plot(x,T(jcentro,:)-273.15,'LineWidth',1.5);

xlabel('x [m]');
ylabel('Temperatura [C]');

title('Perfil de Temperatura no Centro - Regime Permanente');

grid on;


%% ================================================================
% 14. REGIME TRANSIENTE
% ================================================================
%
% Condicao inicial:
%
% T(x,y,0) = Tinf
%
% Equacao:
%
% rho*cp*t*dT/dt =
% k*t*Laplaciano(T)
% + q
% - h(T-Tinf)
%
% ================================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf(' REGIME TRANSIENTE\n');
fprintf('====================================================\n');


% Temperatura inicial
Tt = Tinf*ones(Ny,Nx);


% Passo de tempo
dt = 0.01;            % [s]

% Tempo total
tempo_total = 10;     % [s]

% Numero de passos
nt = round(tempo_total/dt);


% Numero de Fourier
Fo = alpha*dt/dx^2;

fprintf('dt = %.5f s\n',dt);
fprintf('Tempo total = %.2f s\n',tempo_total);
fprintf('Fourier = %.5f\n',Fo);


if Fo > 0.25

    error('ERRO: passo de tempo instavel. Reduza dt.');

end


% Historico
historico_t = zeros(nt,1);
historico_Tmax = zeros(nt,1);
historico_Tmin = zeros(nt,1);
historico_Tmed = zeros(nt,1);


fprintf('Calculando regime transiente...\n');


for n = 1:nt

    Told = Tt;


    % ------------------------------------------------------------
    % NOS INTERNOS
    % ------------------------------------------------------------

    laplaciano = ...
        ( ...
        Told(2:Ny-1,3:Nx) - ...
        2*Told(2:Ny-1,2:Nx-1) + ...
        Told(2:Ny-1,1:Nx-2) ...
        )/dx^2 ...
        + ...
        ( ...
        Told(3:Ny,2:Nx-1) - ...
        2*Told(2:Ny-1,2:Nx-1) + ...
        Told(1:Ny-2,2:Nx-1) ...
        )/dy^2;


    Tt(2:Ny-1,2:Nx-1) = ...
        Told(2:Ny-1,2:Nx-1) ...
        + dt/(rho*cp*espessura) * ...
        ( ...
        k*espessura*laplaciano ...
        + q(2:Ny-1,2:Nx-1) ...
        - h*(Told(2:Ny-1,2:Nx-1)-Tinf) ...
        );


    % ------------------------------------------------------------
    % BORDAS
    % ADIABATICAS NA DIRECAO DO PLANO
    % ------------------------------------------------------------

    % esquerda
    Tt(2:Ny-1,1) = Tt(2:Ny-1,2);

    % direita
    Tt(2:Ny-1,Nx) = Tt(2:Ny-1,Nx-1);

    % inferior
    Tt(1,2:Nx-1) = Tt(2,2:Nx-1);

    % superior
    Tt(Ny,2:Nx-1) = Tt(Ny-1,2:Nx-1);


    % Cantos
    Tt(1,1) = 0.5*(Tt(1,2)+Tt(2,1));

    Tt(1,Nx) = 0.5*(Tt(1,Nx-1)+Tt(2,Nx));

    Tt(Ny,1) = 0.5*(Tt(Ny,2)+Tt(Ny-1,1));

    Tt(Ny,Nx) = ...
        0.5*(Tt(Ny,Nx-1)+Tt(Ny-1,Nx));


    % ------------------------------------------------------------
    % HISTORICO
    % ------------------------------------------------------------

    historico_t(n) = n*dt;

    historico_Tmax(n) = max(Tt(:));

    historico_Tmin(n) = min(Tt(:));

    historico_Tmed(n) = mean(Tt(:));

end


fprintf('Regime transiente concluido.\n\n');


%% ================================================================
% 15. RESULTADOS - REGIME TRANSIENTE
% ================================================================

Tmax_trans = max(Tt(:));
Tmin_trans = min(Tt(:));
Tmed_trans = mean(Tt(:));

fprintf('RESULTADOS DO REGIME TRANSIENTE\n');
fprintf('----------------------------------------------------\n');

fprintf('Temperatura maxima = %.3f K\n',Tmax_trans);
fprintf('Temperatura maxima = %.3f C\n',Tmax_trans-273.15);

fprintf('Temperatura minima = %.3f K\n',Tmin_trans);
fprintf('Temperatura minima = %.3f C\n',Tmin_trans-273.15);

fprintf('Temperatura media  = %.3f K\n',Tmed_trans);
fprintf('Temperatura media  = %.3f C\n\n',Tmed_trans-273.15);


%% ================================================================
% 16. MAPA DE TEMPERATURA - REGIME TRANSIENTE
% ================================================================

figure;

contourf(X,Y,Tt-273.15,20);

xlabel('x [m]');
ylabel('y [m]');

title('Distribuicao de Temperatura - Regime Transiente');

colorbar;
grid on;


%% ================================================================
% 17. LINHAS DE TEMPERATURA - TRANSIENTE
% ================================================================

figure;

contour(X,Y,Tt-273.15,15);

xlabel('x [m]');
ylabel('y [m]');

title('Linhas de Temperatura - Regime Transiente');

colorbar;
grid on;


%% ================================================================
% 18. EVOLUCAO DA TEMPERATURA MAXIMA
% ================================================================

figure;

plot(historico_t,...
     historico_Tmax-273.15,...
     'LineWidth',1.5);

xlabel('Tempo [s]');
ylabel('Temperatura maxima [C]');

title('Evolucao da Temperatura Maxima - Regime Transiente');

grid on;


%% ================================================================
% 19. EVOLUCAO DA TEMPERATURA MEDIA
% ================================================================

figure;

plot(historico_t,...
     historico_Tmed-273.15,...
     'LineWidth',1.5);

xlabel('Tempo [s]');
ylabel('Temperatura media [C]');

title('Evolucao da Temperatura Media - Regime Transiente');

grid on;


%% ================================================================
% 20. COMPARACAO DOS DOIS REGIMES
% ================================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf(' COMPARACAO\n');
fprintf('====================================================\n');

fprintf('Permanente:\n');
fprintf('  Tmax = %.2f C\n',Tmax_perm-273.15);
fprintf('  Tmin = %.2f C\n',Tmin_perm-273.15);
fprintf('  Tmed = %.2f C\n\n',Tmed_perm-273.15);

fprintf('Transiente no tempo final:\n');
fprintf('  Tmax = %.2f C\n',Tmax_trans-273.15);
fprintf('  Tmin = %.2f C\n',Tmin_trans-273.15);
fprintf('  Tmed = %.2f C\n\n',Tmed_trans-273.15);

fprintf('====================================================\n');
fprintf(' FIM DA ANALISE\n');
fprintf('====================================================\n');
