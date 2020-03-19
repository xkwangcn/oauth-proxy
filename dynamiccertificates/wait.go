/*
Copyright 2019 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package dynamiccertificates

import (
	"time"

	"k8s.io/apimachinery/pkg/util/wait"
)

// pollImmediateUntil tries a condition func until it returns true, an error or stopCh is closed.
//
// pollImmediateUntil runs the 'condition' before waiting for the interval.
// 'condition' will always be invoked at least once.
//
// This was forked from kube 1.17's k8s.io/apimachinery/pkg/util/wait
func pollImmediateUntil(interval time.Duration, condition wait.ConditionFunc, stopCh <-chan struct{}) error {
	done, err := condition()
	if err != nil {
		return err
	}
	if done {
		return nil
	}
	select {
	case <-stopCh:
		return wait.ErrWaitTimeout
	default:
		return wait.PollUntil(interval, condition, stopCh)
	}
}
