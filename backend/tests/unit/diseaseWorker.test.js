const { Worker } = require('bullmq');
const diseaseService = require('../../src/services/diseaseService');

// Mock external dependencies
jest.mock('bullmq', () => {
  return {
    Worker: jest.fn().mockImplementation((queueName, processor, options) => {
      return {
        on: jest.fn(),
        close: jest.fn(),
        processor,
      };
    }),
  };
});

jest.mock('../../src/services/diseaseService', () => ({
  scanDisease: jest.fn(),
}));

jest.mock('../../src/config/redis', () => ({
  connection: {},
}));

jest.mock('../../src/utils/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
}));

// Require the worker ONCE
require('../../src/workers/diseaseWorker');
// Get the single instance created
const workerInstance = Worker.mock.results[0].value;

describe('Disease Worker', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should process job and return result successfully', async () => {
    const mockResult = { id: 1, diseaseName: 'Test Disease' };
    diseaseService.scanDisease.mockResolvedValueOnce(mockResult);

    const mockJob = {
      id: 'job-123',
      data: {
        userId: 1,
        imageUrl: '/test.jpg',
      },
    };

    // Execute the processor directly
    const result = await workerInstance.processor(mockJob);

    expect(diseaseService.scanDisease).toHaveBeenCalledWith(1, '/test.jpg');
    expect(result).toEqual(mockResult);
  });

  it('should throw error if diseaseService fails', async () => {
    const mockError = new Error('API failure');
    diseaseService.scanDisease.mockRejectedValueOnce(mockError);

    const mockJob = {
      id: 'job-456',
      data: {
        userId: 2,
        imageUrl: '/test2.jpg',
      },
    };

    // Expect the processor to throw
    await expect(workerInstance.processor(mockJob)).rejects.toThrow('API failure');
    expect(diseaseService.scanDisease).toHaveBeenCalledWith(2, '/test2.jpg');
  });
});
