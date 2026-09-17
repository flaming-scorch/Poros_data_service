/**
 * Utility functions for transforming data between database (snake_case) and API (camelCase)
 */

/**
 * Convert a snake_case string to camelCase
 */
export function snakeToCamel(str: string): string {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

/**
 * Convert a camelCase string to snake_case
 */
export function camelToSnake(str: string): string {
  return str.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);
}

/**
 * Transform an object from snake_case to camelCase
 */
export function transformToCamelCase<T extends Record<string, any>>(obj: T): any {
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(transformToCamelCase);
  }

  if (typeof obj !== 'object') {
    return obj;
  }

  const transformed: any = {};
  for (const [key, value] of Object.entries(obj)) {
    const camelKey = snakeToCamel(key);
    
    if (value instanceof Date) {
      transformed[camelKey] = value.toISOString();
    } else if (Array.isArray(value)) {
      transformed[camelKey] = value.map(transformToCamelCase);
    } else if (value !== null && typeof value === 'object') {
      transformed[camelKey] = transformToCamelCase(value);
    } else {
      transformed[camelKey] = value;
    }
  }

  return transformed;
}

/**
 * Transform an object from camelCase to snake_case
 */
export function transformToSnakeCase<T extends Record<string, any>>(obj: T): any {
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(transformToSnakeCase);
  }

  if (typeof obj !== 'object') {
    return obj;
  }

  const transformed: any = {};
  for (const [key, value] of Object.entries(obj)) {
    const snakeKey = camelToSnake(key);
    
    if (Array.isArray(value)) {
      transformed[snakeKey] = value.map(transformToSnakeCase);
    } else if (value !== null && typeof value === 'object' && !(value instanceof Date)) {
      transformed[snakeKey] = transformToSnakeCase(value);
    } else {
      transformed[snakeKey] = value;
    }
  }

  return transformed;
}


