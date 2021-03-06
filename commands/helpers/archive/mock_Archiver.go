// Code generated by mockery v1.1.0. DO NOT EDIT.

package archive

import (
	context "context"
	os "os"

	mock "github.com/stretchr/testify/mock"
)

// MockArchiver is an autogenerated mock type for the Archiver type
type MockArchiver struct {
	mock.Mock
}

// Archive provides a mock function with given fields: ctx, files
func (_m *MockArchiver) Archive(ctx context.Context, files map[string]os.FileInfo) error {
	ret := _m.Called(ctx, files)

	var r0 error
	if rf, ok := ret.Get(0).(func(context.Context, map[string]os.FileInfo) error); ok {
		r0 = rf(ctx, files)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}
