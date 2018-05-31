import NProgress from 'nprogress';

export const wrap_fetch = fetch_fn => {
  return function (...args) {
    if (this.fetching) {
      return;
    }

    this.fetching = true;
    NProgress.start();
    fetch_fn.bind(this)(...args)
      .then(response => {
        NProgress.done();
        this.fetching = false;
        if (response.status === 500) {
          this.$emit('message', {
            type: 'error',
            message: response.statusText,
          });
        } else {
          this.$emit('message', {
            type: 'info',
            message: 'success',
          });
        }
      })
      .catch(error => {
        NProgress.done();
        this.fetching = false;
        this.$emit('message', {
          type: 'error',
          message: error,
        });
      });
  };
};

