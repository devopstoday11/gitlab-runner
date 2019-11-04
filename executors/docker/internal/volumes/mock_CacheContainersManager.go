// Code generated by mockery v1.0.0. DO NOT EDIT.

// This comment works around https://github.com/vektra/mockery/issues/155

package volumes

import (
	context "context"

	mock "github.com/stretchr/testify/mock"
)

// MockCacheContainersManager is an autogenerated mock type for the CacheContainersManager type
type MockCacheContainersManager struct {
	mock.Mock
}

// Cleanup provides a mock function with given fields: ctx, ids
func (_m *MockCacheContainersManager) Cleanup(ctx context.Context, ids []string) chan bool {
	ret := _m.Called(ctx, ids)

	var r0 chan bool
	if rf, ok := ret.Get(0).(func(context.Context, []string) chan bool); ok {
		r0 = rf(ctx, ids)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(chan bool)
		}
	}

	return r0
}

// Create provides a mock function with given fields: containerName, containerPath
func (_m *MockCacheContainersManager) Create(containerName string, containerPath string) (string, error) {
	ret := _m.Called(containerName, containerPath)

	var r0 string
	if rf, ok := ret.Get(0).(func(string, string) string); ok {
		r0 = rf(containerName, containerPath)
	} else {
		r0 = ret.Get(0).(string)
	}

	var r1 error
	if rf, ok := ret.Get(1).(func(string, string) error); ok {
		r1 = rf(containerName, containerPath)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

// FindOrCleanExisting provides a mock function with given fields: containerName, containerPath
func (_m *MockCacheContainersManager) FindOrCleanExisting(containerName string, containerPath string) string {
	ret := _m.Called(containerName, containerPath)

	var r0 string
	if rf, ok := ret.Get(0).(func(string, string) string); ok {
		r0 = rf(containerName, containerPath)
	} else {
		r0 = ret.Get(0).(string)
	}

	return r0
}
