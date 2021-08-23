goo = beamPath;

% Inputs of cavity parameters (length d = 9.97cm, mirror curvatures R1 = 10cm and R2 = flat (infinite)
d = 0.0997; %0.0997;
R1 = 0.1;
R2 = Inf;
target_waist_radius = 50e-6;
ITM_thickness = 57e-3;

% SPosition of fixed optical components (m):
%lens in here
z45=0.3; % 45 degree mirror after collimator output
zM1=0.5; % First steering mirror
zM2=1.8; % Second steering mirror
%lens in here
zM3=12.1; % Third steering mirror
zM4=13.6; % Fourth steering mirror
%lens in here
zCav=14.8-ITM_thickness; %Distance to first cavity mirror (curved)
zCavEnd= 14.8+d; %Distance to end of cavity mirror (flat)
zTotal = zCavEnd; %Distance to waist in cavity, occurs on flat cavity mirror

% Seed and target beams: 
goo.seedWaist(1.165e-3,0,1550e-9); % Seed beam is input from collimator, at z=0m, lambda 1550nm. WaistSize is output beam radius
goo.targetWaist(target_waist_radius,zCavEnd,1550e-9); % Beam waist input mirror of symmetric cavity, distance is to waist position, wavelength.

% Add fixed optical components as components - flatMirror(Z,label)and
% curvedMirror(radiusOfCurvature,Z,label)
goo.addComponent(component.flatMirror(z45,'45Deg'));
goo.addComponent(component.flatMirror(zM1,'SM1'));
goo.addComponent(component.flatMirror(zM2,'SM2'));
goo.addComponent(component.flatMirror(zM3,'SM3'));
goo.addComponent(component.flatMirror(zM4,'SM4'));
goo.addComponent(component.dielectric(R1, R2, ITM_thickness, 3.422, zCav, 'CavInputMirror')); %thick lens with inputs (R1, R2, thickness, n, Z, label)
%goo.addComponent(component.curvedMirror(R1,zCav,'CavInputMirror')); %input for a thin curved mirror
goo.addComponent(component.flatMirror(zCavEnd,'CavEndMirror'));

zdomain = -0.05:0.001:zCavEnd+0.05;

% List of focal lengths of lenses available to us (SVN Laseroptik list):
    %List given in radii of curvature, divide by 2 at end for focal length
radiusofcurvatureList = [75, 100, 200, 500, 3000, 2000, 250, 750, 1000, 50, 1500, 5000, 150, 300, 350, 4000, 10000] *(1e-3);
focalLengthList = [86.4023, 114.8271, 228.5356, 569.6741, 3412.5197, 2275.3809, 285.3915, 853.9581, 1138.2425, 57.9812, 1706.8116, 5686.7974, 171.6804, 342.2477, 399.1041, 4549.6585, 11372.4921] *(1e-3); % calculated using https://www.edmundoptics.com/knowledge-center/tech-tools/focal-length/
lensList = component.lens(focalLengthList);

% 3 lenses, one between collimator output and 45 degree mirror; one between
    % ZM2 and ZM3; one between ZM4 and cavity. Positions will be optimised
    % for mode overlap.   lens(focalLength,Z,label)
goo.addComponent(component.lens(0.200,0.15,'L1'));
goo.addComponent(component.lens(0.200,zM3-0.2,'L2'));
goo.addComponent(component.lens(0.200,zCav-0.2,'L3'));

figure(266)
clf
subplot(2,1,1)
hold on

[pathList,overlapList] = goo.chooseComponents(...
                'L1',lensList,[0+0.02 z45-0.02],...
                'L2',lensList.duplicate,[zM3-0.5 zM1-0.02],...
                'L3',lensList.duplicate,[zM4+0.02 zCav-0.02],...
                '-vt',.001);

% Cut out all solutions with modematching < 99%
pathList = pathList(overlapList >= 0.98);

% Make an array with the combined position sensitivity of the components
sensitivityList = pathList.positionSensitivity;

%Sort in increasing sensitivity
[sensitivityList,sortIndex] = sort(sensitivityList);
pathList = pathList;

% Plot the best solution
newhandle=pathList(1).plotBeamWidth(zdomain,'r');
pathList(1).plotComponents(zdomain,'r*')
pathList(1).plotBeams(zdomain,'k')

hold off
legend([newhandle],'Optimized Beam Path')
ylabel('Beam Width (m)')
xlabel('Propagation axis (m)')

subplot(2,1,2)
hold on
pathList(1).plotGouyPhase(zdomain,'wrap','b');
pathList(1).plotComponents(zdomain,'r*')
axis tight
grid on
hold off
xlabel('Propagation axis (m)')
ylabel('Gouy Phase (deg)')

% print the component list to the command window
disp(' ')
disp(' Optimized Path Component List:')
display(pathList(1).components)
