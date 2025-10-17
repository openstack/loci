Upload one or more container images.

.. include:: ../../roles/build-container-image/common.rst

.. zuul:rolevar:: upload_container_image_promote
   :type: bool
   :default: true

   If ``true`` (the default), then this role will upload the image(s)
   to the container registry with special tags designed for use by the
   promote-container-image role.  Set to ``false`` to use
   this role to directly upload images with the final tag (e.g., as
   part of an un-gated release job).
