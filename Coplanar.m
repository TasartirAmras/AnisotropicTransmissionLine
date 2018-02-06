%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILENAME:         Coplanar.m
% COURSE:           EE5322--21st Century Electromagnetics
% INSTRUCTOR:       Raymond C. Rumpf
% NAME:             Manuel F. Martinez
% SEMESTER:         Spring 2018
% DUE DATE:         02/06/2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% RESTORE MATLAB STATE
clear all;
close all;
clc;

% UNITS
meters      = 1;
seconds     = 1;
degrees     = pi/180;
F           = 1;
H           = 1;

% CONSTANTS
e0 = 8.85418782e-12 * F/meters;
u0 = 1.25663706e-6 * H/meters;
N0 = sqrt(u0/e0);
c0 = 299792458 * meters/seconds;

% OPEN FIGURE WINDOW
figure('Color','w');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DASHBOARD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TRANSMISSION LINE PARAMETERS
w = 2.5;                % Width of trace
s = 0.1;                % Spacing between traces
ersup = 1.0 * eye(3,3); % Superstrate Tensor
ersub = 2.5 * eye(3,3); % Substrate Tensor

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEFINE GRID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% GRID PARAMETERS
BUFF  = 3*w;
Sx    = BUFF + s + w + BUFF;
Sy    = 2*BUFF + 1;
Nx    = 512;
Ny    = 512;

% FIRST GUESS AT RESOLUTION
dx = Sx/Nx;
dy = Sy/Ny;

% SNAP GRID TO CRITICAL DIMENSIONS
nx = ceil(s/dx);
dx = s/nx;

% COMPUTE 2x GRID
Nx2 = 2*Nx;
dx2 = dx/2;
Ny2 = 2*Ny;
dy2 = dy/2;

% GRID AXES
xa = [0:Nx-1]*dx; xa = xa - mean(xa);
ya = [0:Ny-1]*dy; ya = ya - mean(ya);

% 2x GRID AXES
xa2 = [0:Nx2-1]*dx2; xa2 = xa2 - mean(xa2);
ya2 = [0:Ny2-1]*dy2; ya2 = ya2 - mean(ya2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BUILD DEVICE ON GRID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% INITIALIZE SIGNALS
SIG.V     = [0 1];
SIG.GND   = zeros(Nx,Ny);
SIG.SIG1  = SIG.GND;

% FORCE CONDUCTORS
SIG.GND(:,1)     = 1;
SIG.GND(:,Ny)    = 1;
SIG.GND(1,:)     = 1;
SIG.GND(Nx,:)    = 1;
nx1 = round((w + 2*s)/dx);
nx2 = 1 + floor((Nx-nx1)/2);
nx3 = nx2 + nx1 - 1;
ny = 1 + floor(Ny/2);
SIG.GND(1:nx2,ny) = 1;
SIG.GND(nx3:Nx,ny) = 1;
nx4 = w/dx;
nx5 = 1 + floor((Nx-nx4)/2);
nx6 = nx5 + nx4 - 1;
SIG.SIG1(nx5:nx6,ny) = 1;

imagesc(xa,ya,(SIG.GND | SIG.SIG1)');

% BUILD PERMITTIVITIES IN 2x GRID
ER2xx = ersup(1,1)*ones(Nx2,Ny2);       % Fill with superstrate
ER2xy = ersup(1,2)*ones(Nx2,Ny2);
ER2yx = ersup(2,1)*ones(Nx2,Ny2);
ER2yy = ersup(2,2)*ones(Nx2,Ny2);
ny2   = 1 + floor(Ny2/2) + 2;
ER2xx(:,ny2:Ny2) = ersub(1,1);  % Fill with substrate
ER2xy(:,ny2:Ny2) = ersub(1,2);
ER2yx(:,ny2:Ny2) = ersub(2,1);
ER2yy(:,ny2:Ny2) = ersub(2,2);

% PARSE TO 1x GRID
DEV.ERxx = ER2xx(2:2:Nx2,1:2:Ny2);
DEV.ERxy = ER2xy(1:2:Nx2,2:2:Ny2);
DEV.ERyx = ER2yx(2:2:Nx2,1:2:Ny2);
DEV.ERyy = ER2yy(1:2:Nx2,2:2:Ny2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PERFORM SIMULATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CALL anisotropicTL.m
RES = [dx dy];
TL = anisotropicTL(RES,DEV,SIG);

% Calculate total field
E = sqrt(abs(TL.Ex).^2 + abs(TL.Ey).^2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% POST-PROCESS DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SHOW NUMERICAL PARAMETERS ON CONSOLE
disp(['C    = ' num2str(TL.C/1e-12,'%3.5f') ' pF/m']);
disp(['L    = ' num2str(TL.L/1e-09,'%3.5f') ' nH/m']);
disp(['Z0   = ' num2str(TL.Z0) ' Ohms']);
disp(['nEff = ' num2str(TL.nEff)]);

% VISUALIZE POTENTIAL AND FIELDS
imagesc(xa,ya,TL.V');
colormap(hot);
colorbar;
axis equal tight;
set(gca,'FontSize',12,'FontWeight','bold');
title('Electric Potential V','FontSize',14);
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);

figure('Color','w');
imagesc(xa,ya,E');
caxis([0 1]);
colorbar
colormap(hot);
axis equal tight;
set(gca,'FontSize',12,'FontWeight','bold');
title('|E|','FontSize',14);
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);
hold on;

% ADD QUIVER
[Y,X] = meshgrid(ya,xa);
quiver(X(1:14:Nx,1:14:Ny),Y(1:14:Nx,1:14:Ny),TL.Ex(1:14:Nx,1:14:Ny),...
      TL.Ey(1:14:Nx,1:14:Ny),'Color','w');
hold off;

% VISUALIZE DIELECTRIC TENSORS
figure('Color','w');
a = subplot(2,2,1);
set(a,'FontSize',12);
imagesc(xa2,ya2,ER2xx');
title('$\varepsilon_{xx}$','FontSize',14,'Interpreter','LaTex');
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);
caxis([1.5 +1.5*max(ER2xx(:))]);
colorbar;
colormap(hot);

a = subplot(2,2,2);
set(a,'FontSize',12);
imagesc(xa2,ya2,ER2xy');
title('$\varepsilon_{xy}$','FontSize',14,'Interpreter','LaTex');
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);
caxis([-2*max(ER2xy(:)) +2*max(ER2xy(:))]);
colorbar;
colormap(hot);

a = subplot(2,2,3);
set(a,'FontSize',12);
imagesc(xa2,ya2,ER2yx');
title('$\varepsilon_{yx}$','FontSize',14,'Interpreter','LaTex');
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);
caxis([-2*max(ER2yx(:)) +2*max(ER2yx(:))]);
colorbar;
colormap(hot);

a = subplot(2,2,4);
set(a,'FontSize',12);
imagesc(xa2,ya2,ER2yy');
title('$\varepsilon_{yy}$','FontSize',14,'Interpreter','LaTex');
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);
caxis([1.5 +1.5*max(ER2yy(:))]);
colorbar;
colormap(hot);

% PLOT CONDUCTORS
figure('Color','w');
imagesc(xa,ya,SIG.GND');
title('GND','FontSize',14);
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);
colormap(gray);
colorbar;
caxis([0 1]);

figure('Color','w');
imagesc(xa,ya,SIG.SIG1');
title('SIG1','FontSize',14);
xlabel('x (mm)','FontSize',12);
ylabel('y (mm)','FontSize',12);
colormap(gray);
colorbar;
caxis([0 1]);
