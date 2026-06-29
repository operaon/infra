-- Add missing columns to functional_tests
ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "testType" VARCHAR(20);

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "repetitions" INTEGER;

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "timeSeconds" DECIMAL(5,2);

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "notes" TEXT;

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "bergScores" JSONB;

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "bergTotalScore" INTEGER;

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "bergClassification" VARCHAR(50);

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "sitToStand5RepsTime" DECIMAL(5,2);

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "sitToStand5RepsPredicted" DECIMAL(5,2);

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "sitToStand5RepsPercentage" DECIMAL(5,2);

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "sitToStand5RepsClassification" VARCHAR(50);

ALTER TABLE functional_tests 
ADD COLUMN IF NOT EXISTS "sitToStand1MinReps" INTEGER;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_functional_tests_testType ON functional_tests("testType");
CREATE INDEX IF NOT EXISTS idx_functional_tests_repetitions ON functional_tests("repetitions");
CREATE INDEX IF NOT EXISTS idx_functional_tests_patientId ON functional_tests("patientId");
