% test struct:

grades = [];
level = 5;
semester = 'Fall';
subject = 'Math';
student = 'John_Doe';
fieldnames = {semester subject student}
newGrades_Doe = [85, 89, 76, 93, 85, 91, 68, 84, 95, 73];
grades = setfield(grades, {level}, ...
fieldnames{:}, {10, 21:30}, ...
newGrades_Doe);

spindle(1).sensor = 'Cz';
spindle(1).peakOnsets = [1:7];
spindle(1).duration = 2300;
spindle(1).rms = [1:7];
spindle(1).p2p = [1:7];

spindle(2).sensor = 'F3';
spindle(2).peakOnsets = [1:5];
spindle(2).duration = 300;
spindle(2).rms = [1:5];
spindle(2).p2p = [1:5];


s(2).f = 'two';